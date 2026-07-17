# Wholesale Credit Risk Engine (IFRS 9 / GRAP 104 Compliance Pipeline)

## Project Overview
I built this project to automate how a bank calculates its credit impairment reserves (Expected Credit Losses) for retail and corporate loans under IFRS 9 and GRAP 104 rules[cite: 12]. The backend handles roughly 250,000 active customer loan accounts inside Google BigQuery[cite: 12], and the front end exposes an interactive risk tracking dashboard built in Looker Studio[cite: 12].

## Data Pipeline Mechanics
Instead of loading raw data into the BI layer, I wrote a modular, multi-stage BigQuery view to clean, map, and calculate the risk metrics upstream[cite: 12]:

* **Step 1: Overdue Tracking (`CTE_First`):** Calculates exactly how many days a payment is overdue (`Days_Past_Due`) using `CURRENT_DATE()` against the contractual due date, while computing the monthly accrued interest income per account[cite: 12].
* **Step 2: Regulatory Staging (`CTE_Second`):** Maps loans into four strict compliance buckets based on aging: Current ($\le0$ days), Stage 1(Late) (1–45 days), Stage 2(Arrears) (46–90 days), and Stage 3(Default/NPL) (91+ days)[cite: 12].
* **Step 3: Expected Credit Loss Engine (`CTE_Third`):** Applies the specific provisioning logic[cite: 12]. Because unsecured loans carry higher loss-given-default risk, the script heavily penalizes them, scaling up to a $70\%$ cash reserve penalty for unsecured defaults versus $50\%$ for asset-backed loans[cite: 12].
* **Step 4: Summary Aggregation:** Summarizes the transactional details by risk stage and loan type so the visualization dashboard loads instantly[cite: 12].

## Production Engineering Fixes
* **Enforcing Date Boundaries:** Swapped dynamic, environment-dependent date filters for an explicit `CURRENT_DATE()` call[cite: 12]. This ensures chronological aging tracking remains stable and perfectly auditable over rolling compliance timelines[cite: 12].
* **Offloading Dashboard Computation:** Shifting heavy conditional `CASE` statements and table joins into a pre-compiled BigQuery view prevents dashboard lag, reducing runtime rendering down to flat summary data[cite: 12].
* **Fixing UI Data Truncation:** Corrected a layout flaw where the reporting interface dropped critical asset bands (like Stage 1) due to space limits[cite: 12]. Resizing the canvas and fixing the sorting order restored the full chronological credit profile[cite: 12].

## Looker Studio Dashboard
* **Impairment Risk Concentration ("Stacked Bar Chart.png"):** A stacked column chart exposing required reserve capital, clearly showing how non-performing loans drain cash reserves[cite: 12].
* **Portfolio Yield Performance ("Bar Chart.png"):** A column chart mapping expected interest revenue directly against credit stages, illustrating how trailing arrears erode top-line margins[cite: 12].