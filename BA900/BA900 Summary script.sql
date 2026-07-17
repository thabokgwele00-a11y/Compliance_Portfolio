CREATE OR REPLACE VIEW `SARB_Reporting.vw_BA900_Summary` AS
WITH CTE_First AS (
  SELECT b.Current_Balance, c.Sector_Category, COALESCE(b.Product_Code, 'UNMAPPED_SUSPENSE') AS Product_Code,
  DATE_TRUNC(b.Reporting_Date, MONTH) AS Reporting_Month
  FROM `SARB_Reporting.Fact_Balances` b JOIN `SARB_Reporting.Dim_Customers` c ON b.Account_Number = c.Account_Number
),
CTE_Second AS (
  SELECT f.*, COALESCE(m.Liquidity_Status, 'UNMAPPED') AS Liquidity_Status
  FROM CTE_First f LEFT JOIN `SARB_Reporting.Dim_Product_Mapping` m ON f.Product_Code = m.Product_Code
),
CTE_Third AS (
  SELECT *,
  CASE
    WHEN Product_Code = 'UNMAPPED_SUSPENSE' THEN Current_Balance
    WHEN (Sector_Category = 'Household' AND Liquidity_Status = 'Liquid') THEN ROUND((Current_Balance), 2)
    WHEN (Sector_Category = 'Household' AND Liquidity_Status = 'Fixed') THEN ROUND((Current_Balance * 0.5), 2)
    WHEN (Sector_Category = 'Non-Financial Corporation' AND Liquidity_Status = 'Liquid') THEN ROUND((Current_Balance * 0.85), 2)
    WHEN (Sector_Category = 'Non-Financial Corporation' AND Liquidity_Status = 'Fixed') THEN ROUND((Current_Balance * 0.3), 2)
    WHEN (Sector_Category IN ('Public Sector', 'Financial Corporation') AND Liquidity_Status = 'Liquid') THEN ROUND((Current_Balance * 0.7), 2)
    WHEN (Sector_Category IN ('Public Sector', 'Financial Corporation') AND Liquidity_Status = 'Fixed') THEN ROUND((Current_Balance * 0.2), 2)
    ELSE 0
    END AS Weighted_Liquidity
  FROM CTE_Second
)
SELECT
  Reporting_Month,
  Liquidity_Status,
  Sector_Category,
  ROUND((SUM(Current_Balance)), 2) AS Total_Book_Balance,
  ROUND((SUM(Weighted_Liquidity)), 2) AS Total_Weighted_Liquidity,
  ROUND((SUM(Current_Balance) - SUM(Weighted_Liquidity)), 2) AS Liquidity_Gap
FROM
  CTE_Third
GROUP BY
  Reporting_Month, Liquidity_Status, Sector_Category
HAVING
  SUM(Current_Balance) > 10000000