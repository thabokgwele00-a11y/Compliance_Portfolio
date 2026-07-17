CREATE OR REPLACE VIEW `FICA_Pipeline.vw_Split_Deposit_Triage` AS
WITH CTE_First AS (
  SELECT *,
  SUM(Transaction_Amount_ZAR) OVER(PARTITION BY Customer_ID, Branch_ID, EXTRACT(DATE FROM Transaction_Timestamp)) AS Daily_Deposit_Total,
  COUNT(Transaction_ID) OVER(PARTITION BY Customer_ID, Branch_ID, EXTRACT(DATE FROM Transaction_Timestamp)) AS Daily_Deposit_Count
  FROM `FICA_Pipeline.Fact_Banking_Transactions`
  WHERE Transaction_Type = 'Cash Deposit'
),
CTE_Second AS (
  SELECT *,
  CASE
    WHEN (Transaction_Amount_ZAR < 10000 AND Daily_Deposit_Total > 24999.99 AND Daily_Deposit_Count > 1) THEN 'SPLIT DEPOSIT SUSPICION'
    ELSE 'NORMAL'
    END AS Compliance_Risk_Flag
  FROM CTE_First
)
SELECT
  Transaction_ID,
  Account_Number,
  Customer_ID,
  Transaction_Timestamp,
  Branch_ID,
  Transaction_Amount_ZAR,
  ROUND(Daily_Deposit_Total, 2) AS Daily_Deposit_Total,
  Daily_Deposit_Count
FROM
  CTE_Second
WHERE
  Compliance_Risk_Flag = 'SPLIT DEPOSIT SUSPICION'