CREATE SCHEMA `Credit_Risk`;
CREATE OR REPLACE TABLE `Credit_Risk.Fact_Loans` AS
WITH Date_Pool AS (
  SELECT 
    -- Generates a sequence of 18 separate monthly payment due dates
    DATE_ADD(DATE '2024-11-30', INTERVAL month_offset MONTH) AS Payment_Due_Date
  FROM UNNEST(GENERATE_ARRAY(0, 17)) AS month_offset
),
Row_Seed AS (
  SELECT 
    row_num,
    -- Generates a pseudo-random seed between 0.0 and 1.0 for each row using hashes
    ABS(MOD(FARM_FINGERPRINT(CAST(row_num AS STRING)), 1000000)) / 1000000.0 AS rand_seed
  FROM UNNEST(GENERATE_ARRAY(1, 250000)) AS row_num
)
SELECT
  CONCAT('LN-', LPAD(CAST(s.row_num AS STRING), 8, '0')) AS Account_Number,
  
  -- Assigns due dates evenly across rows from our monthly pool
  d.Payment_Due_Date,
  
  -- Step 1: Assign Loan Type distribution (40% Unsecured / 60% Secured)
  CASE 
    WHEN s.rand_seed < 0.40 THEN 'Unsecured'
    ELSE 'Secured'
  END AS Loan_Type,
  
  -- Step 2: Set Loan Principal Amounts based on realistic financial tiers
  CASE
    WHEN s.rand_seed < 0.10 THEN ROUND(15000 + (s.rand_seed * 450000), 2)  -- Entry retail / micro-loans
    WHEN s.rand_seed BETWEEN 0.10 AND 0.60 THEN ROUND(150000 + (s.rand_seed * 1200000), 2) -- Mid-market / vehicle / personal lines
    ELSE ROUND(2500000 + (s.rand_seed * 8500000), 2) -- Commercial exposure tiers
  END AS Principal_Amount,
  
  -- Step 3: Set Annual Interest Rates (Unsecured gets penalized with higher rates)
  CASE
    WHEN s.rand_seed < 0.40 THEN ROUND(0.14 + (s.rand_seed * 0.11), 4) -- 14% to 25% for unsecured credit risk
    ELSE ROUND(0.08 + (s.rand_seed * 0.06), 4) -- 8% to 14% asset-backed prime lending rates
  END AS Annual_Interest_Rate,
  
  -- Step 4: Inject realistic credit risk into the Payment Due Dates
  -- We shift the payment due date backward for specific rows to simulate real-world arrears buckets
  CASE
    -- 80% of the book is perfectly current or paid early
    WHEN s.rand_seed < 0.80 THEN DATE_ADD(d.Payment_Due_Date, INTERVAL CAST(FLOOR(s.rand_seed * 15) AS INT64) DAY)
    
    -- 12% enters Stage 1 Late (1 to 45 Days Past Due)
    WHEN s.rand_seed BETWEEN 0.80 AND 0.92 THEN DATE_SUB(d.Payment_Due_Date, INTERVAL CAST(1 + FLOOR((s.rand_seed - 0.80) * 360) AS INT64) DAY)
    
    -- 5% drifts into Stage 2 Arrears (46 to 90 Days Past Due)
    WHEN s.rand_seed BETWEEN 0.92 AND 0.97 THEN DATE_SUB(d.Payment_Due_Date, INTERVAL CAST(46 + FLOOR((s.rand_seed - 0.92) * 880) AS INT64) DAY)
    
    -- 3% falls heavily into Stage 3 Non-Performing Loans / Default (91+ Days Past Due)
    ELSE DATE_SUB(d.Payment_Due_Date, INTERVAL CAST(91 + FLOOR((s.rand_seed - 0.97) * 4000) AS INT64) DAY)
  END AS Actual_Payment_Date
FROM Row_Seed s
CROSS JOIN Date_Pool d;