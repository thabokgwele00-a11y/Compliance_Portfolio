CREATE OR REPLACE TABLE `FICA_Pipeline.Fact_Banking_Transactions` AS
WITH Ground_Data AS (
  SELECT 
    CONCAT('TXN-AML-', LPAD(CAST(idx AS STRING), 7, '0')) AS Transaction_ID,
    CONCAT('ZA-ACC-', LPAD(CAST(MOD(idx, 150) + 1 AS STRING), 6, '0')) AS Account_Number,
    CONCAT('ZA-CUST-', LPAD(CAST(MOD(idx, 100) + 1 AS STRING), 6, '0')) AS Customer_ID,
    -- Spreads the 10,000 transactions back over a true 14-day window (20,160 minutes)
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL MOD(idx, 20160) MINUTE) AS Transaction_Timestamp,
    CASE 
      WHEN MOD(idx, 4) = 0 THEN 'Cash Deposit'
      WHEN MOD(idx, 4) = 1 THEN 'Cash Withdrawal'
      WHEN MOD(idx, 4) = 2 THEN 'EFT Transfer'
      ELSE 'Merchant Refund'
    END AS Transaction_Type,
    CASE 
      WHEN MOD(idx, 5) = 0 THEN 'BR-SANDTON-01'
      WHEN MOD(idx, 5) = 1 THEN 'BR-BRAKPAN-02'
      WHEN MOD(idx, 5) = 2 THEN 'BR-JOBURG-CBD'
      WHEN MOD(idx, 5) = 3 THEN 'BR-PRETORIA-E'
      ELSE 'BR-DIGITAL-CH'
    END AS Branch_ID,
    ROUND(50.00 + (MOD(idx, 90) * 50.00) + (MOD(idx, 7) * 3.25), 2) AS Baseline_Amount,
    idx
  FROM UNNEST(GENERATE_ARRAY(1, 10000)) AS idx
)
SELECT 
  Transaction_ID,
  Account_Number,
  Customer_ID,
  -- Force our target smurfing rows to land on a solid history date 3 days ago
  CASE 
    WHEN Customer_ID = 'ZA-CUST-000014' THEN TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 DAY)
    ELSE Transaction_Timestamp
  END AS Transaction_Timestamp,
  CASE 
    WHEN Customer_ID = 'ZA-CUST-000014' THEN 'Cash Deposit'
    ELSE Transaction_Type
  END AS Transaction_Type,
  Branch_ID,
  CASE 
    WHEN Customer_ID = 'ZA-CUST-000014' AND MOD(idx, 3) = 0 THEN 9450.00 
    WHEN Customer_ID = 'ZA-CUST-000014' AND MOD(idx, 3) = 1 THEN 8900.00
    WHEN Customer_ID = 'ZA-CUST-000014' AND MOD(idx, 3) = 2 THEN 7200.00
    ELSE Baseline_Amount
  END AS Transaction_Amount_ZAR
FROM Ground_Data;