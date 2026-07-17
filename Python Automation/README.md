Forensic Fraud Triage & Automated Alerting Engine
## Project Overview
This project is an automated forensic pipeline designed to identify sophisticated financial fraud patterns that standard, rule-based systems typically miss. By leveraging BigQuery’s windowing capabilities and Python automation, the system detects high-velocity attacks like "Merchant Sweeps" and "Structured Smash-and-Grabs" in real-time. It doesn't just alert; it generates actionable forensic reports for immediate investigation.

## Technical Stack
Data Warehouse: Google BigQuery (Serverless SQL processing).

Feature Engineering: Advanced SQL analytical window functions (LAG, ROWS BETWEEN, SUM() OVER).

Automation: Google Colab / Python (Cloud SDK for BigQuery).

Data Delivery: Automated CSV export for forensic audit teams.

## Forensic Logic
The engine monitors three specific, high-risk attack vectors:

CNPP Merchant Sweeps: Detects automated, multi-transaction "sweeps" against single merchants that deviate significantly from a user's normal spending baseline.

Structured Smash-and-Grabs: Identifies coordinated terminal attacks where an adversary rapidly alternates between digital and physical channels to bypass velocity-based detection.

Single-Source Volume Spikes: Catches isolated, high-value transactions that trigger alerts based on deviation from historical spending norms.

## Automated Operational Workflow
This isn't a passive dashboard—it’s an active operational tool. The Python automation script handles the end-to-end lifecycle:

Schema Management: Automatically synchronizes the forensic view (vw_Forensic_Alerts_Triage) with the transaction ledger.

Detection Logic: Executes the SQL triage view to filter out benign transaction noise and isolate only high-risk anomalies.

Automated Alerting: Immediately triggers an alarm if suspicious transactions are found.