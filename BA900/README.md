BA 900 Regulatory Reporting Engine (SARB Compliance Pipeline)
## Project Overview
This project handles the automation for Form BA 900 compliance under the South African Banks Act, 1990. The pipeline processes around 500,000 raw balance records in Google BigQuery and pumps the clean, aggregated metrics into a risk dashboard in Looker Studio.

## How the Data Flows
The transformation logic relies on four steps inside a BigQuery view to clean, map, and weight the ledger data:

Step 1: Fixing Timestamps (CTE_First): Joins ledger rows with customer profiles and uses DATE_TRUNC to standardize daily transaction dates into uniform calendar months.

Step 2: Table Joins (CTE_Second): Runs a LEFT JOIN against product mapping tables. It uses COALESCE to catch unmatched rows early so missing codes don't break the final group structures.

Step 3: Applying Risk Weights (CTE_Third): Evaluates records row-by-row to calculate weighted liquidity reserves. Any unmapped entries are hit with a mandatory 100% run-off penalty (Current_Balance×1.0), forcing the bank to play it safe and over-provision for unidentifiable capital.

Step 4: Filtering for Materiality: Aggregates the final totals, finds the liquidity gap, and drops any groups below R10,000,000 using a HAVING clause to keep the dashboard snappy.

## Real-World Issues Fixed
Plugging Migration Gaps: Legacy system migrations frequently leave product codes blank. A standard database join would just drop these rows or leak blank values onto the front end, which triggers immediate red flags during a regulatory audit. The pipeline intercepts these missing codes early and forces them into an explicit 'UNMAPPED' label so the entire ledger balances perfectly down to the cent.

Speeding Up the Dashboard: Running heavy conditional logic across half a million rows at runtime makes dashboards painfully slow. Moving the joins and CASE statement weights directly into a BigQuery view ensures Looker Studio only has to read flat, pre-aggregated monthly data.

## Looker Studio Layout
The front-end dashboard translates the data into three clean interfaces for risk officers:

Form BA 900 Matrix Grid: A dynamic pivot table matching gross balances directly against weighted liquidity reserves by institutional sector.

Liquidity Gap Trends: A historical line chart tracking net liquidity gaps over an 18-month timeline to flag sudden funding drawdowns.

Funding Concentration Profile: A stacked column chart visualizing the bank's liability mix to see exactly how much capital relies on volatile corporate funds versus stable retail deposits.