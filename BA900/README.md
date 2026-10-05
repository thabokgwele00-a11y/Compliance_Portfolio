# BA 900-Style Sector and Liquidity Summary (BigQuery and Looker Studio)

A SQL pipeline that summarises a synthetic bank deposit ledger by **institutional sector** and **liquidity profile**, applies illustrative liquidity weights, and presents the results in a **Looker Studio** dashboard. It is modelled loosely on the sector and maturity breakdown idea behind the South African Reserve Bank's Form BA 900.

> **Note:** This is a learning and portfolio project. All data is synthetic. The project does **not** reproduce the actual BA 900 return, and the liquidity weights are illustrative parameters chosen for this exercise. See [Limitations](#limitations).

---

## Project Overview

The project covers three stages:

1. **Data generation:** three BigQuery tables (customers, product mapping and balances) populated with synthetic data.
2. **Transformation:** a BigQuery view that joins the tables, handles missing product codes, applies weights and aggregates by month, liquidity status and sector.
3. **Reporting:** a Looker Studio dashboard with a pivot matrix, a line chart and a stacked bar chart.

---

## Regulatory Context

Form BA 900 is the monthly return on the institutional and maturity breakdown of liabilities and assets that banks submit under regulation 62 of the Regulations relating to Banks (Banks Act 94 of 1990). Its primary purpose is to collect selected balance sheet information for economic statistics.

This project borrows the idea of breaking balances down by institutional sector and maturity. It does not reproduce the form's tables or line items, and BA 900 itself does not prescribe liquidity weights or a liquidity gap. Those elements are the project's own constructs.

---

## Technical Stack

| Layer | Tool |
|---|---|
| Data warehouse and query engine | Google BigQuery (SQL) |
| Techniques | CTEs, joins, `LEFT JOIN` with `COALESCE`, `CASE` logic, aggregation with `HAVING`, SQL views |
| Dashboard | Google Looker Studio |
| Data | Synthetic: 100,000 accounts, 15 products, 119,898 balance records |

---

## Repository Contents

| File | Purpose |
|---|---|
| `Data_generation.sql` | Creates the three source tables and runs data-quality check queries |
| `BA900_Summary_script.sql` | Creates the view `SARB_Reporting.vw_BA900_Summary` |
| `Dim_Customers.png` | Preview of the customer dimension |
| `Dim_Product_Mapping.png` | Preview of the product mapping table |
| `Fact_Balances.png` | Preview of the balances fact table |
| `Pivot_Table.png` | Dashboard page: sector and liquidity matrix |
| `Stacked_Bar_Graph_View.png` | Dashboard page: funding concentration chart |

---

## Data Model

**`Dim_Customers`** has 100,000 accounts with `Account_Number`, `Sector_Category`, `Customer_ID`, `Registration_Year` and `Province`. Sectors are assigned by account number: 42,000 Non-Financial Corporation, 38,000 Household, 12,000 Public Sector and 8,000 Financial Corporation.

**`Dim_Product_Mapping`** has 15 product codes, each tagged **Liquid** (6 products, for example demand deposits, savings, call accounts and money market) or **Fixed** (9 products, for example fixed and notice deposits, structured deposits and negotiable CDs).

**`Fact_Balances`** holds 119,898 balance records. Each is a randomly sampled account and product combination, with a balance range that depends on the sector and a reporting month chosen at random between January 2024 and June 2025. About 1% of rows have a null `Product_Code`, which simulates gaps left by legacy system migrations.

---

## Pipeline Logic

The view `vw_BA900_Summary` works in three CTE layers and a final aggregation:

1. **Join and standardise (`CTE_First`):** joins balances to customers, replaces null product codes with `UNMAPPED_SUSPENSE` using `COALESCE`, and truncates the reporting date to the month.
2. **Map to liquidity status (`CTE_Second`):** left-joins to the product mapping. Any balance without a match is given the status `UNMAPPED`.
3. **Apply weights (`CTE_Third`):** multiplies each balance by a weight that depends on sector and liquidity status:

| Sector | Liquid | Fixed |
|---|---|---|
| Household | 100% | 50% |
| Non-Financial Corporation | 85% | 30% |
| Public Sector and Financial Corporation | 70% | 20% |
| Unmapped product (any sector) | 100% | 100% |

   The weights are illustrative. Unmapped balances are deliberately given the full 100% weight so that they are not understated. Any combination not listed above falls through to a weight of 0.

4. **Aggregate:** groups by reporting month, liquidity status and sector, and returns the total book balance, the total weighted amount and the **liquidity gap** (book balance minus weighted amount). Groups with a total book balance of R10 million or less are excluded with a `HAVING` clause.

---

## Dashboard

The Looker Studio report ("BA900 Summary") has three pages:

1. **Pivot table (`Pivot_Table.png`):** a matrix of sector against liquidity status showing the gap, the weighted amount and the gross book value, with summary figures for the whole dataset: R837.3B total book balance, R505.0B weighted and R332.4B gap.
2. **Line chart:** a month-by-month view of the view's measures.
3. **Stacked bar chart (`Stacked_Bar_Graph_View.png`):** gross book balance by sector, split into Liquid, Fixed and Unmapped.

---

## Limitations

* **Not the actual return:** the project does not follow the BA 900 table structure or line items, and the weights and liquidity gap are the project's own constructs.
* **Synthetic and random:** sector mix, balance ranges and product mix are invented. For example, Financial Corporations make up about two thirds of total balances only because of the ranges used in the generator, so the sector shares carry no real meaning. The generator is not seeded, so results change slightly each time it is run.
* **Random reporting dates:** each balance record is given a random month and is not part of a monthly series per account, so month-to-month movement on the line chart reflects the generator and not a trend.
* **Materiality filter:** the `HAVING` clause removes small groups from the view. The Household UNMAPPED group does not appear in the pivot, which is consistent with that filter removing it (household balances are small in the synthetic data). This means the dashboard totals may not equal the full ledger.
* **Not pre-aggregated:** a standard BigQuery view runs its query each time the dashboard reads it. It keeps the logic in the warehouse but does not store pre-computed results.

---

## Possible Improvements

* Remove or lower the materiality filter, and report excluded groups separately so that every unmapped balance stays visible.
* Add a reconciliation check comparing the view's total with the total in `Fact_Balances`.
* Replace the illustrative weights with parameters taken from a relevant prudential liquidity framework.
* Restructure the output to follow the actual BA 900 tables and line items.
* Use a materialised view or a scheduled table for faster dashboard performance.
* Generate a consistent monthly balance series per account so that trends are meaningful.

---

## How to Reproduce

1. Create a BigQuery dataset named `SARB_Reporting`.
2. Run `Data_generation.sql` to create the three tables.
3. Run `BA900_Summary_script.sql` to create the view.
4. Connect the view to Looker Studio and build the three report pages.
