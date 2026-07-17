CREATE OR REPLACE TABLE `SARB_Reporting.Dim_Customers` AS
WITH 
  numbered AS (
    SELECT 
      CONCAT('ZA', LPAD(CAST(ROW_NUMBER() OVER() AS STRING), 10, '0')) AS Account_Number,
      ROW_NUMBER() OVER() AS rn
    FROM UNNEST(GENERATE_ARRAY(1, 100000)) AS id
  )
SELECT 
  Account_Number,
  CASE 
    WHEN rn <= 42000 THEN 'Non-Financial Corporation'  
    WHEN rn <= 80000 THEN 'Household'                  
    WHEN rn <= 92000 THEN 'Public Sector'             
    ELSE 'Financial Corporation'                         
  END AS Sector_Category,
  CONCAT(
    CASE 
      WHEN rn <= 42000 THEN 'CORP'
      WHEN rn <= 80000 THEN 'HH'
      WHEN rn <= 92000 THEN 'GOV'
      ELSE 'FIN'
    END,
    '-',
    LPAD(CAST(rn AS STRING), 8, '0')
  ) AS Customer_ID,
  2000 + CAST(FLOOR(RAND() * 25) AS INT64) AS Registration_Year,
  CASE CAST(FLOOR(RAND() * 9) AS INT64)
    WHEN 0 THEN 'Gauteng' 
    WHEN 1 THEN 'Western Cape' 
    WHEN 2 THEN 'KwaZulu-Natal'
    WHEN 3 THEN 'Eastern Cape' 
    WHEN 4 THEN 'Free State' 
    WHEN 5 THEN 'Mpumalanga'
    WHEN 6 THEN 'Limpopo' 
    WHEN 7 THEN 'North West' 
    WHEN 8 THEN 'Northern Cape'
  END AS Province
FROM numbered;

CREATE OR REPLACE TABLE `SARB_Reporting.Dim_Product_Mapping` AS
SELECT * FROM UNNEST([
  STRUCT('DEMAND_DEPOSIT' AS Product_Code, 'Liquid' AS Liquidity_Status, 'Cheque/Current Account' AS Product_Desc),
  ('SAVINGS_PLUS', 'Liquid', 'High-yield Savings'),
  ('CALL_ACCOUNT', 'Liquid', 'Instant Access'),
  ('MONEY_MARKET', 'Liquid', 'Money Market Fund'),
  ('FIXED_DEPOSIT_30D', 'Fixed', '30-day Fixed Deposit'),
  ('FIXED_DEPOSIT_90D', 'Fixed', '90-day Fixed Deposit'),
  ('FIXED_DEPOSIT_1YR', 'Fixed', '1-year Fixed Deposit'),
  ('NOTICE_DEPOSIT_32D', 'Fixed', '32-day Notice Account'),
  ('NOTICE_DEPOSIT_90D', 'Fixed', '90-day Notice Account'),
  ('STRUCTURED_DEPOSIT', 'Fixed', 'Structured Product'),
  ('NCD_3M', 'Fixed', 'Negotiable CD 3 Month'),
  ('NCD_6M', 'Fixed', 'Negotiable CD 6 Month'),
  ('NCD_12M', 'Fixed', 'Negotiable CD 12 Month'),
  ('OFFSHORE_ACCOUNT', 'Liquid', 'Foreign Currency Account'),
  ('TRUST_ACCOUNT', 'Liquid', 'Trust/Client Account')
]);



CREATE OR REPLACE TABLE `SARB_Reporting.Fact_Balances` AS
WITH 
  
  customers AS (
    SELECT Account_Number, Sector_Category 
    FROM `SARB_Reporting.Dim_Customers`
  ),
  
  
  products AS (
    SELECT Product_Code, Liquidity_Status 
    FROM `SARB_Reporting.Dim_Product_Mapping`
  ),
  

  combinations AS (
    SELECT 
      c.Account_Number,
      c.Sector_Category,
      p.Product_Code,
      p.Liquidity_Status,
      
      CASE p.Product_Code
        WHEN 'DEMAND_DEPOSIT' THEN 0.35
        WHEN 'SAVINGS_PLUS' THEN 0.20
        WHEN 'CALL_ACCOUNT' THEN 0.12
        WHEN 'MONEY_MARKET' THEN 0.08
        WHEN 'FIXED_DEPOSIT_30D' THEN 0.07
        WHEN 'FIXED_DEPOSIT_90D' THEN 0.05
        WHEN 'FIXED_DEPOSIT_1YR' THEN 0.04
        WHEN 'NOTICE_DEPOSIT_32D' THEN 0.03
        WHEN 'NOTICE_DEPOSIT_90D' THEN 0.02
        WHEN 'STRUCTURED_DEPOSIT' THEN 0.01
        WHEN 'NCD_3M' THEN 0.01
        WHEN 'NCD_6M' THEN 0.01
        WHEN 'NCD_12M' THEN 0.005
        WHEN 'OFFSHORE_ACCOUNT' THEN 0.003
        ELSE 0.002
      END AS product_weight,
      RAND() AS rand_val
    FROM customers c
    CROSS JOIN products p
  ),
  
  
  balances AS (
    SELECT 
      Account_Number,
      Sector_Category,
      Product_Code,
      Liquidity_Status,
      
      RAND() AS balance_rand,
      
      CASE Sector_Category
        
        WHEN 'Household' THEN 
          CASE 
            WHEN RAND() < 0.60 THEN ROUND(RAND() * 50000, 2)
            WHEN RAND() < 0.85 THEN ROUND(50000 + RAND() * 200000, 2)
            WHEN RAND() < 0.97 THEN ROUND(250000 + RAND() * 750000, 2)
            ELSE ROUND(1000000 + RAND() * 4000000, 2)
          END
        
        
        WHEN 'Non-Financial Corporation' THEN 
          CASE 
            WHEN RAND() < 0.30 THEN ROUND(RAND() * 500000, 2)
            WHEN RAND() < 0.60 THEN ROUND(500000 + RAND() * 2000000, 2)
            WHEN RAND() < 0.85 THEN ROUND(2500000 + RAND() * 5000000, 2)
            ELSE ROUND(7500000 + RAND() * 25000000, 2)
          END
        
        
        WHEN 'Public Sector' THEN 
          CASE 
            WHEN RAND() < 0.40 THEN ROUND(100000 + RAND() * 2000000, 2)
            WHEN RAND() < 0.70 THEN ROUND(2000000 + RAND() * 8000000, 2)
            WHEN RAND() < 0.90 THEN ROUND(10000000 + RAND() * 40000000, 2)
            ELSE ROUND(50000000 + RAND() * 100000000, 2)
          END
        
        
        ELSE 
          CASE 
            WHEN RAND() < 0.30 THEN ROUND(1000000 + RAND() * 9000000, 2)
            WHEN RAND() < 0.60 THEN ROUND(10000000 + RAND() * 40000000, 2)
            WHEN RAND() < 0.85 THEN ROUND(50000000 + RAND() * 150000000, 2)
            ELSE ROUND(200000000 + RAND() * 300000000, 2)
          END
      END AS Current_Balance,
      
      
      DATE('2024-01-01') + INTERVAL CAST(FLOOR(RAND() * 18) AS INT64) MONTH AS Reporting_Date
      
    FROM combinations
   
    WHERE RAND() < product_weight * 1.2
  )
  

SELECT 
  Account_Number,
 
  CASE WHEN RAND() < 0.01 THEN NULL ELSE Product_Code END AS Product_Code,
  Current_Balance,
  Reporting_Date
FROM balances
WHERE Current_Balance > 0
LIMIT 500000;





SELECT 'Dim_Customers' AS Table_Name, COUNT(*) AS Row_Count FROM `SARB_Reporting.Dim_Customers`
UNION ALL
SELECT 'Dim_Product_Mapping', COUNT(*) FROM `SARB_Reporting.Dim_Product_Mapping`
UNION ALL
SELECT 'Fact_Balances', COUNT(*) FROM `SARB_Reporting.Fact_Balances`;


SELECT 
  Sector_Category, 
  COUNT(*) AS customer_count,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM `SARB_Reporting.Dim_Customers`
GROUP BY Sector_Category
ORDER BY customer_count DESC;


SELECT 
  c.Sector_Category,
  COUNT(*) AS balance_records,
  ROUND(AVG(b.Current_Balance), 2) AS avg_balance,
  ROUND(MIN(b.Current_Balance), 2) AS min_balance,
  ROUND(MAX(b.Current_Balance), 2) AS max_balance,
  ROUND(APPROX_QUANTILES(b.Current_Balance, 100)[OFFSET(50)], 2) AS median_balance
FROM `SARB_Reporting.Fact_Balances` b
JOIN `SARB_Reporting.Dim_Customers` c ON b.Account_Number = c.Account_Number
GROUP BY c.Sector_Category
ORDER BY avg_balance DESC;


SELECT 
  COUNT(*) AS total_rows,
  COUNTIF(Product_Code IS NULL) AS null_product_rows,
  ROUND(100 * COUNTIF(Product_Code IS NULL) / COUNT(*), 2) AS null_percentage
FROM `SARB_Reporting.Fact_Balances`;


SELECT 
  p.Liquidity_Status,
  COUNT(DISTINCT p.Product_Code) AS num_products,
  COUNT(*) AS balance_count,
  ROUND(SUM(b.Current_Balance), 2) AS total_balance
FROM `SARB_Reporting.Fact_Balances` b
JOIN `SARB_Reporting.Dim_Product_Mapping` p ON b.Product_Code = p.Product_Code
WHERE b.Product_Code IS NOT NULL
GROUP BY p.Liquidity_Status;