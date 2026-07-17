CREATE OR REPLACE VIEW `FICA_Pipeline.vw_Forensic_Alerts_Triage` AS
WITH CTE_First AS (
  SELECT 
    Transaction_ID,
    Customer_ID,
    Transaction_Timestamp,
    Channel,
    Amount,
    Merchant_ID,
    Terminal_ID,
    LAG(Channel, 1) OVER(PARTITION BY Customer_ID ORDER BY Transaction_Timestamp) AS Previous_Channel,
    LAG(Transaction_Timestamp, 5) OVER(PARTITION BY Customer_ID ORDER BY Transaction_Timestamp) AS Fifth_Last_Txn_Time,
    LAG(Transaction_Timestamp, 9) OVER(PARTITION BY Customer_ID ORDER BY Transaction_Timestamp) AS Ninth_Last_Txn_Time,
    AVG(Amount) OVER(PARTITION BY Customer_ID ORDER BY Transaction_Timestamp ROWS BETWEEN 100 PRECEDING AND 1 PRECEDING) AS Rolling_Avg,
    ROW_NUMBER() OVER(PARTITION BY Customer_ID ORDER BY Transaction_Timestamp) AS Row_Num
  FROM `Fraud_Detection.Fact_Transactions`
),
CTE_Second AS (
  SELECT *,
    LAG(Row_Num) OVER(PARTITION BY Customer_ID, Terminal_ID ORDER BY Transaction_Timestamp) AS Previous_Terminal_Row_Num,
    LAG(Row_Num) OVER(PARTITION BY Customer_ID, Merchant_ID ORDER BY Transaction_Timestamp) AS Previous_Merchant_Row_Num
  FROM CTE_First
),
CTE_Third AS (
  SELECT *,
    TIMESTAMP_DIFF(Transaction_Timestamp, Fifth_Last_Txn_Time, MINUTE) AS Merchant_Time_Window_Minutes,
    TIMESTAMP_DIFF(Transaction_Timestamp, Ninth_Last_Txn_Time, MINUTE) AS Terminal_Time_Window_Minutes,
    SUM(CASE 
      WHEN Previous_Terminal_Row_Num IS NULL THEN 1
      WHEN (Row_Num - Previous_Terminal_Row_Num) > 9 THEN 1
      ELSE 0 END) OVER(PARTITION BY Customer_ID ORDER BY Transaction_Timestamp ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS Terminal_Count,
    SUM(CASE
      WHEN Previous_Merchant_Row_Num IS NULL THEN 1
      WHEN (Row_Num - Previous_Merchant_Row_Num) > 5 THEN 1
      ELSE 0 END) OVER(PARTITION BY Customer_ID ORDER BY Transaction_Timestamp ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS Merchant_Count
  FROM CTE_Second
),
CTE_Fourth AS (
  SELECT *,
    CASE
      WHEN (Merchant_Time_Window_Minutes <= 15 AND Merchant_Count >= 4 AND Amount > (Rolling_Avg * 7)) THEN 'CNPP MERCHANT SWEEP'
      WHEN (Terminal_Time_Window_Minutes <= 15 AND Channel != Previous_Channel AND Terminal_Count >= 6 AND Amount > (Rolling_Avg * 20)) THEN 'STRUCTURED SMASH-AND-GRAB'
      WHEN Amount > (Rolling_Avg * 7) THEN 'SINGLE-SOURCE VOLUME SPIKE'
      ELSE 'NONE'
    END AS Fraud_Type
  FROM CTE_Third
)
SELECT
  Transaction_ID,
  Customer_ID,
  Transaction_Timestamp,
  Channel,
  Amount,
  Merchant_ID,
  Terminal_ID,
  Merchant_Time_Window_Minutes,
  Terminal_Time_Window_Minutes,
  Merchant_Count,
  Terminal_Count,
  Fraud_Type
FROM
  CTE_Fourth
WHERE
  Fraud_Type != 'NONE';