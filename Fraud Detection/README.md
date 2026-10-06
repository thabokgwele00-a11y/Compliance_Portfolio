# Fraud Alert Triage Engine (BigQuery SQL and Looker Studio)

A rule-based BigQuery SQL view that uses window functions to flag **unusually large and rapid card transactions** against each customer's recent history, with a **Looker Studio** dashboard for reviewing the alerts.

> **Note:** This is a learning and portfolio project. All data is synthetic. The alerts are indicators for review, not confirmed fraud, and the test data does not line up fully with the detection rules. See [Results](#results) and [Limitations](#limitations).

---

## Project Overview

The project covers three stages:

1. **Data generation:** a synthetic card transaction table with three fraud-like patterns planted in it.
2. **Detection logic:** a BigQuery view that uses `LAG`, rolling averages and `ROW_NUMBER` to measure speed, variety and size of transactions per customer, then applies three ordered rules.
3. **Reporting:** a four-page Looker Studio dashboard (scorecards, donut chart, stacked bar chart and alert table).

---

## Technical Stack

| Layer | Tool |
|---|---|
| Data warehouse and query engine | Google BigQuery (SQL) |
| Techniques | CTEs, window functions (`LAG`, `AVG() OVER`, `SUM() OVER`, `ROW_NUMBER`), `CASE` logic, SQL views |
| Dashboard | Google Looker Studio |
| Data | 120,590 synthetic transactions |

---

## Repository Contents

| File | Purpose |
|---|---|
| `Data_generation.sql` | Creates `Fraud_Detection.Fact_Transactions` with baseline and planted transactions |
| `Forensic_Alerts_Triage_Script.sql` | Creates the view `vw_Forensic_Alerts_Triage` containing the detection rules |
| `Fact_Transactions.png` | Preview of the generated table |
| `Scorecards.png` | Dashboard page: alert totals |
| `Pie_Chart.png` | Dashboard page: alert types |
| `Stacked_Bar_Graph.png` | Dashboard page: amount by alert type and channel |
| `Table.png` | Dashboard page: alert table |

---

## Data Model

`Fact_Transactions` has seven fields: `Transaction_ID`, `Customer_ID`, `Transaction_Timestamp`, `Channel` (`POS_TERMINAL` or `ONLINE`), `Amount`, `Merchant_ID` and `Terminal_ID`.

* **Baseline (120,000 rows):** random transactions across 1,000 customers over about 30 days, with amounts between R50 and R500 and a random merchant and terminal each time.
* **Planted "merchant sweep" pattern (250 rows):** 50 customers, each with five R3,500 transactions two minutes apart, every one at a different merchant and terminal.
* **Planted "smash-and-grab" pattern (240 rows):** 30 customers, each with eight R8,500 transactions one minute apart, alternating between channels, every one at a different merchant and terminal.
* **Planted "volume spike" pattern (100 rows):** 50 customers, each with two R4,800 online transactions, two and four days before the data was generated.

---

## Detection Logic

The view works in four CTE layers:

1. **Window features:** for each customer, the previous channel, the timestamps of the fifth and ninth previous transactions, a rolling average of the previous (up to) 100 transaction amounts, and a row number.
2. **Repeat tracking:** the row number of the previous transaction at the same terminal and at the same merchant for that customer.
3. **Counts and time windows:** minutes between the current transaction and the fifth and ninth previous ones, plus approximate distinct counts of merchants (last 6 transactions) and terminals (last 10 transactions).
4. **Rules**, evaluated in this order with the first match winning:
   * **CNPP MERCHANT SWEEP:** fifth previous transaction within 15 minutes, at least 4 distinct merchants, and an amount above 7 times the rolling average.
   * **STRUCTURED SMASH-AND-GRAB:** ninth previous transaction within 15 minutes, a different channel from the previous transaction, at least 6 distinct terminals, and an amount above 20 times the rolling average.
   * **SINGLE-SOURCE VOLUME SPIKE:** an amount above 7 times the rolling average.

The final `SELECT` returns only rows that matched a rule.

---

## Dashboard

1. **Scorecards (`Scorecards.png`):** 597 alerts, R3.4M total flagged amount and 137 customers. The "exposure" figure is the sum of flagged amounts, not confirmed fraud losses.
2. **Alert types (`Pie_Chart.png`):** the share of each alert type.
3. **Amount by type and channel (`Stacked_Bar_Graph.png`):** flagged amounts split by alert type and channel.
4. **Alert table (`Table.png`):** every alert with its time windows and counts.

---

## Results

The view returns **597 alerts**: 506 single-source spikes, 91 merchant sweeps and no smash-and-grabs. Checking the alerts against the planted patterns shows how the rules and the data interact:

| Planted pattern | Rows | Labelled single-source spike | Labelled merchant sweep | Labelled smash-and-grab |
|---|---|---|---|---|
| Merchant sweep | 250 | 249 | 1 | 0 |
| Smash-and-grab | 240 | 150 | 90 | 0 |
| Volume spike | 100 | 100 | 0 | 0 |
| Baseline (not planted) | 7 | 7 | 0 | 0 |

All 590 planted rows raise an alert, but most carry a different label from the one intended:

* The sweep rule needs six transactions within 15 minutes (it looks at the fifth previous one), but each planted sweep has only five. The eight-transaction bursts do meet it from their sixth transaction onwards, so they are labelled as sweeps.
* The smash-and-grab rule needs ten transactions within 15 minutes (it looks at the ninth previous one), but each planted burst has only eight. The rolling average also includes the burst's own earlier transactions, so the 20 times test fails after the second one.
* The 7 baseline alerts are ordinary transactions of R383 to R499. Each is a customer's second transaction, compared against an average based on a single earlier transaction.

---

## Limitations

* **Synthetic data:** results say nothing about how the rules would perform on real transactions.
* **Rules and data do not match:** as shown above, the planted patterns were not built to satisfy the rule thresholds.
* **Count tests do not discriminate:** because every baseline transaction uses a random merchant and terminal, ordinary customers also show about 6 distinct merchants and 10 distinct terminals in a window. Detection effectively rests on the timing and amount tests.
* **Baseline includes attacks:** the rolling average includes a customer's earlier suspicious transactions, which weakens later comparisons.
* **No minimum history:** a customer's first transactions are compared against a very small baseline, which produces false positives.
* **Catch-all rule:** the last rule flags any amount above 7 times the average, so it also absorbs transactions that fail the stricter rules.
* **Indicators only:** an alert is a prompt for analyst review, not a finding of fraud.

---

## Possible Improvements

* Generate planted patterns that match the rule thresholds (for example, six or more sweep transactions and ten or more burst transactions within 15 minutes), or adjust the windows to match the patterns.
* Exclude flagged transactions from the rolling average, and require a minimum transaction history before alerting.
* Use true distinct counts of merchants and terminals.
* Add a date filter so the view can report on a single day.

---

## How to Reproduce

1. Create two BigQuery datasets: `Fraud_Detection` (the generator creates it if missing) and `FICA_Pipeline` (the view is created there).
2. Run `Data_generation.sql` to create the table.
3. Run `Forensic_Alerts_Triage_Script.sql` to create the view.
4. Connect the view to Looker Studio and build the four report pages.

The generator uses random values and the current time, so exact counts, especially the baseline alerts, vary slightly between runs.
