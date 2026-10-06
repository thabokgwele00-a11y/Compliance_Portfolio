CREATE OR REPLACE MODEL `Credit_Risk.CLI_Risk_Model`
OPTIONS(model_type = 'logistic_reg', input_label_cols = ['Defaulted']) AS
SELECT
  Defaulted,
  Current_Utilization_Rate,
  Income_Stability_Score,
  Total_Monthly_Debt_Obligations,
  Years_As_Customer
FROM
  `Credit_Risk.Historical_CLI_Data`;

SELECT * FROM ML.EVALUATE(MODEL `Credit_Risk.CLI_Risk_Model`)

CREATE OR REPLACE VIEW `Credit_Risk.vw_CLI_Campaign_Risk_Scoring` AS
WITH CTE_First AS (
  SELECT * FROM ML.PREDICT(MODEL `Credit_Risk.CLI_Risk_Model`, (SELECT * FROM `Credit_Risk.CLI_Candidates`))
),
CTE_Second AS (
  SELECT 
    Customer_ID, 
    Current_Utilization_Rate,
    Income_Stability_Score,
    Total_Monthly_Debt_Obligations,
    Years_As_Customer,
    ROUND(((SELECT p.prob FROM UNNEST(predicted_Defaulted_probs) p WHERE label = 1)), 2) AS Default_Probability
  FROM CTE_First
)
SELECT 
  *,
  CASE
    WHEN Default_Probability > 0.55 THEN 'Reject (High Risk)'
    ELSE 'ACCEPT'
    END AS Campaign_Decision
FROM CTE_Second