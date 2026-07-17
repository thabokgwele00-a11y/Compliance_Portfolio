Forensic Fraud Detection Engine (FICA-Compliance)
## Project Overview
This project delivers an automated forensic fraud triage pipeline built directly within BigQuery. Rather than relying on simple static thresholds, the engine uses windowed analytical functions to identify complex, malicious patterns—such as multi-terminal sweeps and structured smash-and-grabs—that typically bypass standard rule-based monitoring.

## Forensic Pipeline Mechanics
The engine operates on a high-velocity fact table (Fact_Transactions) and processes data through an advanced SQL view (vw_Forensic_Alerts_Triage). The pipeline is designed to eliminate "alert fatigue" by filtering out benign activity and isolating only confirmed threat signatures:

Velocity & Windowing: Uses LAG and window-bounded aggregation to calculate the physical speed of transactions (minutes between events) and frequency of use per merchant or terminal.

The Anomaly Detection Engine:

CNPP Merchant Sweeps: Flags high-frequency, rapid-fire transactions across a single merchant identifier that deviate sharply from the account's historical rolling average.

Structured Smash-and-Grabs: Detects high-value, coordinated terminal bursts where an attacker alternates between ONLINE and POS_TERMINAL channels to evade detection.

Single-Source Spikes: Catches isolated, destructive high-value transactions that exceed standard expenditure norms.

Alert Filtering: The production view implements a strict forensic filter (WHERE Fraud_Type != 'NONE'), ensuring that your triage queue contains zero false-positive noise.

## Forensic Operations Hub (Looker Studio)
This dashboard is the operational headquarters for account investigations:

Executive Scorecards: Provides immediate situational awareness with total fraud events detected, aggregate financial exposure (ZAR), and the count of unique compromised cardholders.

Threat Matrix (Donut Chart): Instantly visualizes the composition of your fraud queue, allowing investigators to prioritize specific attack vectors.

Channel Breach Surface (Stacked Column): Maps fraud exposure by ONLINE vs. POS_TERMINAL channels, exposing exactly where your infrastructure is vulnerable.

Forensic Triage Table: A granular list of all flagged anomalies, pre-filtered for immediate review. It includes velocity metrics (Merchant_Count, Terminal_Count) that allow investigators to jump straight into the data during an incident.