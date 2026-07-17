-- Create the target dataset if it does not exist
CREATE SCHEMA IF NOT EXISTS `Fraud_Detection`;

-- Generate the base transaction table with structured fraud anomalies
CREATE OR REPLACE TABLE `Fraud_Detection.Fact_Transactions` AS

-- 1. Normal baseline transactions
WITH Normal_Baseline AS (
  SELECT
    CAST(FLOOR(10000000 + (RAND() * 89999999)) AS STRING) AS Transaction_ID,
    CONCAT('CUST_', LPAD(CAST(CAST(FLOOR(1 + (RAND() * 1000)) AS INT64) AS STRING), 6, '0')) AS Customer_ID,
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL CAST(FLOOR(RAND() * 43200) AS INT64) MINUTE) AS Transaction_Timestamp,
    IF(RAND() > 0.3, 'POS_TERMINAL', 'ONLINE') AS Channel,
    ROUND(50 + (RAND() * 450), 2) AS Amount,
    CONCAT('MERCH_', LPAD(CAST(CAST(FLOOR(1 + (RAND() * 500)) AS INT64) AS STRING), 6, '0')) AS Merchant_ID,
    CONCAT('TERM_', LPAD(CAST(CAST(FLOOR(1 + (RAND() * 500)) AS INT64) AS STRING), 6, '0')) AS Terminal_ID
  FROM
    UNNEST(GENERATE_ARRAY(1, 120000)) AS row_num
),

-- 2. CNPP MERCHANT SWEEP anomalies
-- For Merchant_Count >= 4, we need 4 DIFFERENT merchants in 5 transactions
CNPP_Merchant_Sweep_Anomalies AS (
  SELECT
    CAST(FLOOR(20000000 + (RAND() * 89999999)) AS STRING) AS Transaction_ID,
    CONCAT('CUST_', LPAD(CAST(cust_idx AS STRING), 6, '0')) AS Customer_ID,
    TIMESTAMP_ADD(TIMESTAMP('2026-06-20 10:00:00 UTC'), INTERVAL (step * 2) MINUTE) AS Transaction_Timestamp,
    CASE WHEN MOD(step, 2) = 0 THEN 'ONLINE' ELSE 'POS_TERMINAL' END AS Channel,
    3500.00 AS Amount,
    -- Each transaction uses a DIFFERENT merchant
    CONCAT('MERCH_SWEEP_', CAST(step AS STRING)) AS Merchant_ID,
    -- Each transaction uses a DIFFERENT terminal too
    CONCAT('TERM_SWEEP_', CAST(step AS STRING)) AS Terminal_ID
  FROM
    UNNEST(GENERATE_ARRAY(101, 150)) AS cust_idx,
    UNNEST(GENERATE_ARRAY(1, 5)) AS step
),

-- 3. STRUCTURED SMASH-AND-GRAB anomalies
-- For Terminal_Count >= 6, we need 6 DIFFERENT terminals in 8 transactions
Structured_Smash_Grab_Anomalies AS (
  SELECT
    CAST(FLOOR(30000000 + (RAND() * 89999999)) AS STRING) AS Transaction_ID,
    CONCAT('CUST_', LPAD(CAST(cust_idx AS STRING), 6, '0')) AS Customer_ID,
    TIMESTAMP_ADD(TIMESTAMP('2026-06-21 14:00:00 UTC'), INTERVAL (step * 1) MINUTE) AS Transaction_Timestamp,
    -- Alternating channels for Channel != Previous_Channel
    CASE WHEN MOD(step, 2) = 1 THEN 'ONLINE' ELSE 'POS_TERMINAL' END AS Channel,
    8500.00 AS Amount,
    CONCAT('MERCH_BURST_', CAST(step AS STRING)) AS Merchant_ID,
    -- Each transaction uses a DIFFERENT terminal
    CONCAT('TERM_SMASH_', CAST(step AS STRING)) AS Terminal_ID
  FROM
    UNNEST(GENERATE_ARRAY(201, 230)) AS cust_idx,
    UNNEST(GENERATE_ARRAY(1, 8)) AS step
),

-- 4. SINGLE-SOURCE VOLUME SPIKE anomalies
Single_Source_Spike_Anomalies AS (
  SELECT
    CAST(FLOOR(40000000 + (RAND() * 89999999)) AS STRING) AS Transaction_ID,
    CONCAT('CUST_', LPAD(CAST(cust_idx AS STRING), 6, '0')) AS Customer_ID,
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL (step * 2) DAY) AS Transaction_Timestamp,
    'ONLINE' AS Channel,
    4800.00 AS Amount,
    CONCAT('MERCH_HIGH_', CAST(step AS STRING)) AS Merchant_ID,
    CONCAT('TERM_HIGH_', CAST(step AS STRING)) AS Terminal_ID
  FROM
    UNNEST(GENERATE_ARRAY(301, 350)) AS cust_idx,
    UNNEST(GENERATE_ARRAY(1, 2)) AS step
)

SELECT * FROM Normal_Baseline
UNION ALL
SELECT * FROM CNPP_Merchant_Sweep_Anomalies
UNION ALL
SELECT * FROM Structured_Smash_Grab_Anomalies
UNION ALL
SELECT * FROM Single_Source_Spike_Anomalies;