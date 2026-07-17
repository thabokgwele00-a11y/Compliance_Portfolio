CREATE OR REPLACE VIEW `Credit_Risk.vw_Loan_Book_ECL_Analysis` AS
WITH CTE_First AS (
  SELECT *, 
  DATE_DIFF(CURRENT_DATE(), Payment_Due_Date, DAY) AS Days_Past_Due, ROUND(((Principal_Amount * 1.00) * (Annual_Interest_Rate / 12)), 2) AS Monthly_Interest_Accrual
  FROM `Credit_Risk.Fact_Loans`
),
CTE_Second AS (
  SELECT *,
  CASE
    WHEN Days_Past_Due <= 0 THEN 'Current'
    WHEN Days_Past_Due BETWEEN 1 AND 45 THEN 'Stage 1(Late)'
    WHEN Days_Past_Due BETWEEN 46 AND 90 THEN 'Stage 2(Arrears)'
    ELSE 'Stage 3(Default/NPL)'
    END AS Arrears_Bucket
  FROM CTE_First
),
CTE_Third AS (
  SELECT *,
  CASE
    WHEN (Loan_Type = 'Unsecured' AND Arrears_Bucket IN ('Current', 'Stage 1(Late)')) THEN ROUND((Principal_Amount * 0.05), 2)
    WHEN (Loan_Type = 'Unsecured' AND Arrears_Bucket = 'Stage 2(Arrears)') THEN ROUND((Principal_Amount * 0.25), 2)
    WHEN (Loan_Type = 'Unsecured' AND Arrears_Bucket = 'Stage 3(Default/NPL)') THEN ROUND((Principal_Amount * 0.70), 2)
    WHEN (Loan_Type = 'Secured' AND Arrears_Bucket IN ('Current', 'Stage 1(Late)')) THEN ROUND((Principal_Amount * 0.02), 2)
    WHEN (Loan_Type = 'Secured' AND Arrears_Bucket = 'Stage 2(Arrears)') THEN ROUND((Principal_Amount * 0.15), 2)
    WHEN (Loan_Type = 'Secured' AND Arrears_Bucket = 'Stage 3(Default/NPL)') THEN ROUND((Principal_Amount * 0.5), 2)
    ELSE 0
    END AS Expected_Credit_Loss_Provision
  FROM CTE_Second
)
SELECT
  Arrears_Bucket,
  Loan_Type, 
  COUNT(*) AS Active_Loan_Count, ROUND((SUM(Principal_Amount)), 2) AS Total_Principal_Outstanding,
  ROUND((SUM(Expected_Credit_Loss_Provision)), 2) AS Total_Provision_Required,
  ROUND((SUM(Monthly_Interest_Accrual)), 2) AS Total_Monthly_Interest_Accrual
FROM
  CTE_Third
GROUP BY
  Arrears_Bucket, Loan_Type