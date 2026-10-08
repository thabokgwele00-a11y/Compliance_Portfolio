# Fraud Alert Export Notebook (Python and BigQuery)

A short **Google Colab** notebook that uses the **BigQuery client library** and **pandas** to run a fraud alerts view, report whether any alerts exist and export them to a CSV file.

> **Note:** This is a learning and portfolio project. It is a manually run notebook, not a scheduled or production system. It runs on synthetic data and builds on the [Fraud Alert Triage Engine](#relationship-to-the-fraud-alert-triage-engine) project.

---

## What the Notebook Does

The notebook has five code cells:

1. **Authenticate:** signs in to Google Cloud from Colab.
2. **Connect:** creates a BigQuery client for the project.
3. **Re-create the view:** runs `CREATE OR REPLACE VIEW` for `FICA_Pipeline.vw_Forensic_Alerts_Triage`, using the same detection query as the fraud detection project.
4. **Load and check:** reads the whole view into a pandas DataFrame and prints either an "ALARM" message with the number of alerts or an "all clear" message if there are none.
5. **Export:** writes the DataFrame to `Daily_Fraud_Alert_Report.csv` and downloads it through the browser.

---

## Technical Stack

| Layer | Tool |
|---|---|
| Environment | Google Colab |
| Language and libraries | Python, pandas, `google-cloud-bigquery` |
| Data warehouse | Google BigQuery |
| Output | CSV file |

---

## Repository Contents

| File | Purpose |
|---|---|
| `Automated_Fraud_Reporter.ipynb` | The notebook |
| `Daily_Fraud_Alert_Report.csv` | Sample output from one run |

---

## Sample Output

The sample CSV has 597 alerts and 12 columns (transaction details, time windows, counts and alert type). It covers 137 customers, about R3.4M in flagged amounts and transactions from 23 May to 21 June 2026. Despite the file name, the view has no date filter, so the export covers the whole dataset and not a single day.

---

## Limitations

* **Run manually:** nothing schedules the notebook. It runs when someone opens it and runs the cells.
* **The "alarm" is a printed message:** no email, chat message or other notification is sent.
* **No synchronisation:** re-creating the view does not check or update anything against the transaction table. It simply re-runs the same definition.
* **Manual delivery:** the CSV is downloaded through the browser, not delivered to anyone.
* **Not date-aware:** the "all clear" check and the export both cover the whole view, not just today's transactions.
* **Inherited limitations:** the alert labels come from the fraud detection view, whose rules and test data do not fully line up (see that project's README).
* **Basic scripting:** the notebook has no error handling, and the Google Cloud project ID is written into the code.

---

## Possible Improvements

* Run the notebook or the query on a schedule (for example with a BigQuery scheduled query or a Cloud Scheduler job).
* Send a notification when alerts are found, such as an email.
* Add a date filter and a parameter for the project ID.
* Add error handling.

---

## Relationship to the Fraud Alert Triage Engine

This notebook runs the view created by the **Fraud Alert Triage Engine** project, which contains the data generator, the detection rules, the dashboard and a full discussion of the results and limitations.

---

## How to Run

1. Complete the setup for the Fraud Alert Triage Engine so the `Fraud_Detection.Fact_Transactions` table exists and a `FICA_Pipeline` dataset is available.
2. Open the notebook in Google Colab and replace the project ID in the second cell with your own.
3. Run the cells in order and approve the Google sign-in prompt.
