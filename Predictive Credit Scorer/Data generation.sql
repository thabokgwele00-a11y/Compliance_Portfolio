-- Generate synthetic historical data with rejection patterns - CORRECTED
CREATE OR REPLACE TABLE `Credit_Risk.Historical_CLI_Data` AS
WITH 
-- Base parameters for different customer segments
segments AS (
  SELECT 1 AS segment, 'High Risk' AS segment_name, 
    0.75 AS default_rate, 0.85 AS util_mean, 0.15 AS util_std,
    45 AS income_mean, 15 AS income_std,
    3500 AS debt_mean, 1500 AS debt_std,
    1.5 AS years_mean, 0.8 AS years_std
  UNION ALL SELECT 2, 'Medium-High Risk', 0.45, 0.65, 0.20, 65, 18, 2500, 1200, 3.0, 1.2
  UNION ALL SELECT 3, 'Medium Risk', 0.25, 0.50, 0.22, 72, 16, 1800, 1000, 5.0, 1.8
  UNION ALL SELECT 4, 'Low-Medium Risk', 0.12, 0.35, 0.20, 80, 14, 1200, 800, 7.0, 2.0
  UNION ALL SELECT 5, 'Low Risk', 0.03, 0.20, 0.15, 88, 12, 800, 600, 10.0, 2.5
),

-- Generate 10,000 historical records
historical_data AS (
  SELECT 
    ROW_NUMBER() OVER (ORDER BY RAND()) AS customer_id,
    s.segment,
    CAST(FLOOR(RAND() * (1/0.01)) / 100 AS INT64) AS default_seed,
    CASE 
      WHEN RAND() < s.default_rate THEN 1 
      ELSE 0 
    END AS Defaulted,
    -- Current Utilization Rate (0-100%)
    GREATEST(0.0, LEAST(1.0, 
      s.util_mean + (RAND() - 0.5) * 2 * s.util_std
    )) AS Current_Utilization_Rate,
    -- Income Stability Score (0-100)
    GREATEST(0.0, LEAST(100.0,
      s.income_mean + (RAND() - 0.5) * 2 * s.income_std
    )) AS Income_Stability_Score,
    -- Total Monthly Debt Obligations
    GREATEST(0.0, 
      s.debt_mean + (RAND() - 0.5) * 2 * s.debt_std
    ) AS Total_Monthly_Debt_Obligations,
    -- Years as Customer
    GREATEST(0.1,
      s.years_mean + (RAND() - 0.5) * 2 * s.years_std
    ) AS Years_As_Customer
  FROM segments s
  CROSS JOIN UNNEST(GENERATE_ARRAY(1, 2000)) AS row_num
)

SELECT 
  CAST(Defaulted AS INT64) AS Defaulted,
  ROUND(Current_Utilization_Rate, 2) AS Current_Utilization_Rate,
  ROUND(Income_Stability_Score, 2) AS Income_Stability_Score,
  ROUND(Total_Monthly_Debt_Obligations, 2) AS Total_Monthly_Debt_Obligations,
  ROUND(Years_As_Customer, 2) AS Years_As_Customer
FROM historical_data;

-- Generate candidate profiles - CORRECTED with proper numeric types
CREATE OR REPLACE TABLE `Credit_Risk.CLI_Candidates` AS
WITH 
-- Define rejection-prone profiles
rejection_profiles AS (
  -- Rejection Scenario 1: High utilization + low income stability + high debt
  SELECT 1 AS profile_type, 'High Utilization & Low Income Stability' AS description,
    0.85 AS util_mean, 0.10 AS util_std,
    35.0 AS income_mean, 10.0 AS income_std,
    4500.0 AS debt_mean, 1000.0 AS debt_std,
    2.0 AS years_mean, 1.0 AS years_std,
    1000 AS count
  UNION ALL
  -- Rejection Scenario 2: Very high debt obligations
  SELECT 2, 'Excessive Debt Obligations',
    0.60, 0.15,
    55.0, 12.0,
    8000.0, 2000.0,
    3.0, 1.5,
    1000
  UNION ALL
  -- Rejection Scenario 3: New customer with poor indicators
  SELECT 3, 'New Customer with Poor Metrics',
    0.75, 0.15,
    40.0, 15.0,
    3000.0, 800.0,
    0.5, 0.3,
    1000
  UNION ALL
  -- Rejection Scenario 4: Combination of multiple risk factors
  SELECT 4, 'Multiple Risk Factors',
    0.90, 0.08,
    30.0, 8.0,
    6000.0, 1500.0,
    1.0, 0.5,
    1000
),

-- Acceptance profiles (good customers)
acceptance_profiles AS (
  SELECT 5 AS profile_type, 'Good Customer - Low Risk' AS description,
    0.15, 0.10,
    85.0, 10.0,
    600.0, 300.0,
    12.0, 3.0,
    1500
  UNION ALL
  SELECT 6, 'Good Customer - Medium Risk',
    0.30, 0.12,
    75.0, 12.0,
    1200.0, 400.0,
    8.0, 2.0,
    1500
),

-- Combine all profiles
all_profiles AS (
  SELECT * FROM rejection_profiles
  UNION ALL
  SELECT * FROM acceptance_profiles
),

-- Generate the candidate data
candidate_data AS (
  SELECT 
    CONCAT('CUST_', LPAD(CAST(ROW_NUMBER() OVER (ORDER BY RAND()) AS STRING), 6, '0')) AS Customer_ID,
    CAST(p.profile_type AS INT64) AS profile_type,
    p.description,
    -- Generate values within profile ranges
    GREATEST(0.0, LEAST(1.0,
      p.util_mean + (RAND() - 0.5) * 2 * p.util_std
    )) AS Current_Utilization_Rate,
    GREATEST(0.0, LEAST(100.0,
      p.income_mean + (RAND() - 0.5) * 2 * p.income_std
    )) AS Income_Stability_Score,
    GREATEST(0.0,
      p.debt_mean + (RAND() - 0.5) * 2 * p.debt_std
    ) AS Total_Monthly_Debt_Obligations,
    GREATEST(0.1,
      p.years_mean + (RAND() - 0.5) * 2 * p.years_std
    ) AS Years_As_Customer
  FROM all_profiles p
  CROSS JOIN UNNEST(GENERATE_ARRAY(1, CAST(p.count AS INT64))) AS row_num
)

SELECT 
  Customer_ID,
  CAST(ROUND(Current_Utilization_Rate, 2) AS FLOAT64) AS Current_Utilization_Rate,
  CAST(ROUND(Income_Stability_Score, 2) AS FLOAT64) AS Income_Stability_Score,
  CAST(ROUND(Total_Monthly_Debt_Obligations, 2) AS FLOAT64) AS Total_Monthly_Debt_Obligations,
  CAST(ROUND(Years_As_Customer, 2) AS FLOAT64) AS Years_As_Customer,
  profile_type,
  description
FROM candidate_data
ORDER BY RAND();

-- Create a clean view for Looker Studio with all numeric columns properly typed
CREATE OR REPLACE VIEW `Credit_Risk.vw_CLI_Campaign_Risk_Scoring` AS
WITH CTE_First AS (
  SELECT * FROM ML.PREDICT(MODEL `Credit_Risk.CLI_Risk_Model`, (SELECT * FROM `Credit_Risk.CLI_Candidates`))
),
CTE_Second AS (
  SELECT 
    Customer_ID,
    CAST(Current_Utilization_Rate AS FLOAT64) AS Current_Utilization_Rate,
    CAST(Income_Stability_Score AS FLOAT64) AS Income_Stability_Score,
    CAST(Total_Monthly_Debt_Obligations AS FLOAT64) AS Total_Monthly_Debt_Obligations,
    CAST(Years_As_Customer AS FLOAT64) AS Years_As_Customer,
    profile_type,
    description,
    CAST(ROUND(((SELECT p.prob FROM UNNEST(predicted_Defaulted_probs) p WHERE label = 1)), 4) AS FLOAT64) AS Default_Probability
  FROM CTE_First
)
SELECT 
  Customer_ID,
  Current_Utilization_Rate,
  Income_Stability_Score,
  Total_Monthly_Debt_Obligations,
  Years_As_Customer,
  profile_type,
  description,
  Default_Probability,
  CASE
    WHEN Default_Probability > 0.55 THEN 'Reject (High Risk)'
    ELSE 'ACCEPT'
  END AS Campaign_Decision,
  -- Add a numeric flag for aggregation in Looker Studio
  CAST(CASE
    WHEN Default_Probability > 0.55 THEN 1
    ELSE 0
  END AS INT64) AS Rejection_Flag
FROM CTE_Second;

-- Additional view specifically for Looker Studio bar charts
CREATE OR REPLACE VIEW `Credit_Risk.vw_CLI_Aggregated_Stats` AS
SELECT 
  profile_type,
  description,
  Campaign_Decision,
  COUNT(*) AS customer_count,
  CAST(AVG(Default_Probability) AS FLOAT64) AS avg_default_probability,
  CAST(AVG(Current_Utilization_Rate) AS FLOAT64) AS avg_utilization,
  CAST(AVG(Income_Stability_Score) AS FLOAT64) AS avg_income_stability,
  CAST(AVG(Total_Monthly_Debt_Obligations) AS FLOAT64) AS avg_debt,
  CAST(AVG(Years_As_Customer) AS FLOAT64) AS avg_years,
  CAST(SUM(Rejection_Flag) AS INT64) AS rejected_count
FROM `Credit_Risk.vw_CLI_Campaign_Risk_Scoring`
GROUP BY profile_type, description, Campaign_Decision
ORDER BY profile_type, Campaign_Decision;