# AML Split Deposit Triage Pipeline (FICA Section 28 and 29)

A rule-based analytics pipeline that screens a synthetic retail banking ledger for **structured ("smurfing") cash deposits**, built in **Google BigQuery** (SQL) with a **Looker Studio** triage dashboard.

> **Note:** This is a learning and portfolio project. All data is synthetic and no real customers or institutions are involved. See [Limitations](#limitations) for what the project does and does not demonstrate.

---

## Project Overview

Structuring (commonly called "smurfing") is the practice of breaking a large cash sum into several smaller deposits to avoid regulatory reporting. Monitoring only individual transactions will miss it, so this pipeline looks at **deposit behaviour per customer per calendar day** instead.

The project covers three stages:

1. **Data generation:** a 10,000-row synthetic banking ledger, with one structuring case deliberately planted.
2. **Detection logic:** a BigQuery view that uses SQL window functions to total and count cash deposits per customer, branch and day, then flags rows that meet the structuring conditions.
3. **Reporting:** a three-page Looker Studio dashboard that lets a compliance analyst review the flagged transactions.

---

## Regulatory Context

Under **section 28 of the Financial Intelligence Centre Act 38 of 2001 (FICA)**, accountable institutions must report cash transactions above a prescribed amount to the Financial Intelligence Centre (FIC) in a cash threshold report (CTR).

* **Threshold used in this project:** R24,999.99, the prescribed amount before 14 November 2022.
* **Current position:** Regulation 22B was amended with effect from 14 November 2022, raising the prescribed amount to **R49,999.99**. The same amendments extended the reporting period from two days to three, and removed the requirement to aggregate a series of cash transactions for CTR purposes.
* **Why structuring is still relevant:** FIC Guidance Note 5C recommends that institutions monitor cash transactions below the threshold as well, and consider a **section 29** suspicious and unusual transaction report where one client makes multiple sub-threshold cash transactions.

The pipeline was built against the former R24,999.99 figure. The value is held as a single constant in the view, so updating it to the current threshold is a one-line change. The project is best read as a demonstration of the analytical approach (daily velocity per customer) and not as a statement of current CTR requirements.

---

## Technical Stack

| Layer | Tool |
|---|---|
| Data warehouse and query engine | Google BigQuery (SQL) |
| Analytical techniques | Common table expressions (CTEs), window functions (`SUM() OVER`, `COUNT() OVER`), `CASE` logic, SQL views |
| Dashboard | Google Looker Studio |
| Data | 10,000 synthetic transaction records |

---

## Repository Contents

| File | Purpose |
|---|---|
| `Data_generation_script.sql` | Creates `FICA_Pipeline.Fact_Banking_Transactions` with 10,000 synthetic rows |
| `Split_Deposit_Triage_Script.sql` | Creates the view `FICA_Pipeline.vw_Split_Deposit_Triage` containing the detection logic |
| `Fact_Banking_Transactions.png` | Preview of the generated BigQuery table |
| `Table_View.png` | Dashboard page 1: triage queue |
| `Bar_Graph.png` | Dashboard page 2: flagged records by branch |
| `Pivot_Table_View.png` | Dashboard page 3: deposit matrix by customer and branch |

---

## Data Model

The ledger table `Fact_Banking_Transactions` has these fields:

`Transaction_ID`, `Account_Number`, `Customer_ID`, `Transaction_Timestamp`, `Transaction_Type`, `Branch_ID`, `Transaction_Amount_ZAR`

* **Transaction types:** Cash Deposit, Cash Withdrawal, EFT Transfer, Merchant Refund.
* **Scale:** 100 customers, 150 accounts, 5 branches, with timestamps spread over a 14-day window.
* **Planted case:** customer `ZA-CUST-000014` is forced to make 100 cash deposits of R9,450, R8,900 or R7,200, all at `BR-PRETORIA-E` and all sharing one timestamp three days before the data was generated. Together they total **R852,050**.
* **Baseline data:** the remaining rows are generated using modulo arithmetic on a row index. As a result, each customer is assigned a single transaction type and a single branch, which means some customers only ever make cash deposits.

---

## Detection Logic

The view `vw_Split_Deposit_Triage` works in two CTE layers:

1. **Daily aggregation (`CTE_First`):** filters to cash deposits, then uses window functions partitioned by `Customer_ID`, `Branch_ID` and calendar date to calculate `Daily_Deposit_Total` and `Daily_Deposit_Count` for every row.
2. **Flagging (`CTE_Second`):** labels a row `SPLIT DEPOSIT SUSPICION` when **all** of the following are true:
   * the individual deposit is below R10,000 (an illustrative design parameter, not a legal requirement)
   * the daily total for that customer at that branch exceeds R24,999.99
   * the daily deposit count is greater than 1 (the multiplicity condition)

The final `SELECT` returns only the flagged rows, with their daily total and count alongside each individual deposit.

---

## Dashboard

The Looker Studio report ("Split Deposit Triage") has three pages:

1. **Triage queue (`Table_View.png`):** each flagged deposit shown with its account, customer, branch, transaction ID and amount, next to the `Daily_Deposit_Total` it contributed to. This lets an analyst see how individual deposits add up to a total above the threshold.
2. **Flagged records by branch (`Bar_Graph.png`):** record counts per branch. Pretoria is higher than the other four branches by roughly 100 records, which corresponds to the planted case.
3. **Deposit matrix (`Pivot_Table_View.png`):** customers and timestamps against branches, showing deposit amounts per branch.

---

## Results

The view returns **2,260 flagged rows**:

* 100 rows belong to the planted case (`ZA-CUST-000014`), which is correctly flagged.
* The other **2,160 rows** come from baseline customers whose synthetic data happens to produce several cash deposits per day with totals above the threshold.

In other words, the rule reliably catches the planted pattern, but on this dataset it also flags a large share of ordinary cash-deposit activity. This is discussed below.

---

## Limitations

* **Synthetic data:** the data is generated with simple arithmetic patterns and does not reflect real customer behaviour. Results say nothing about how the rule would perform on real transactions.
* **High volume of flags:** because of how the baseline data is generated, the rule flags most baseline cash deposits. A production rule would need customer risk profiling, expected-activity baselines and tuned thresholds to keep false positives manageable.
* **Single-branch aggregation:** totals are calculated per customer **per branch** per day. Deposits spread across several branches are not combined, so cross-branch structuring would not be detected as written.
* **Outdated threshold:** the pipeline uses the pre-November 2022 R24,999.99 figure (see [Regulatory Context](#regulatory-context)).
* **Flags are indicators only:** a flag is a prompt for analyst review, not a finding of wrongdoing.

---

## Possible Improvements

* Update the constant to the current R49,999.99 threshold and re-run the pipeline.
* Partition by customer and day only, so that deposits across branches are combined.
* Add rolling-window velocity measures (for example, deposits over the previous 24 hours or 7 days) in place of calendar-day totals.
* Compare each customer against their own historical average deposit pattern instead of a fixed threshold.
* Generate more realistic baseline data, with mixed transaction types per customer, so that the rule can be evaluated for false positives properly.

---

## How to Reproduce

1. Create a BigQuery dataset named `FICA_Pipeline`.
2. Run `Data_generation_script.sql` to create the ledger table.
3. Run `Split_Deposit_Triage_Script.sql` to create the triage view.
4. Connect the view to Looker Studio as a data source and build the three report pages.
