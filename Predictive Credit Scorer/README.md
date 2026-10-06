Predictive Credit Risk Engine (BQML Logistic Regression Integration)

## Project Overview
I built a predictive machine learning pipeline using BigQuery ML (BQML) to automate risk appraisal for
 a credit limit increase marketing campaign targeting 25,000 active customer accounts. 
The system maximizes campaign conversion by identifying and approving eligible accounts while 
systematically dropping high-risk profiles based on their predicted probability of default.

## Predictive Pipeline Mechanics
Instead of extracting data to external Python environments, the entire ML lifecycle—training, 
evaluation, and batch scoring—is executed entirely inside the cloud data warehouse to 
eliminate data latency and data egress costs:

Model Training (CLI_Risk_Model): A supervised Logistic Regression classification model 
compiled inside BigQuery using a historical dataset of 150,000 customers. 
The model optimizes weights against a target binary flag (Defaulted) using key indicators:

Current Credit Utilization Rate

Income Stability Score

Total Monthly Debt Obligations (ZAR)

Account Tenure (Years)

Probability Extraction Engine: Operates via a downstream BigQuery production view 
(vw_CLI_Campaign_Risk_Scoring). Because native BQML prediction arrays return complex, 
nested structured arrays, the pipeline uses a cross-join unnesting technique 
(UNNEST(predicted_Defaulted_probs)) to cleanly isolate the explicit scalar probability value
 for label = 1 (Default) at the individual row level.

Risk Appraisal Boundary: Implements a strict corporate risk tolerance cutoff where any 
candidate exhibiting a predicted default probability strictly greater than 55% ($>0.55$) is 
automatically flagged as a high-risk exclusion.

## Looker Studio Dashboard
High-Level Performance Suite (Scorecards): Dynamically tracks total campaign candidates, 
total approved applications, and total blocked profiles using distinct count aggregations to 
eliminate data duplication risks.

Campaign Volume Split (Pie Chart.png): A categorical breakdown illustrating that 57.1% of the marketing 
queue was blocked via predictive modeling, demonstrating massive upfront credit exposure mitigation.

Portfolio Risk Concentration (Bar Chart.png): A distribution chart mapping unique candidate volumes 
directly across the default probability spectrum, exposing exactly how candidate scores cluster.

Risk Stratification Matrix (Stacked Barg Graph.png): A stacked bar visualization mapping customer 
tenure brackets against campaign choices, proving to risk auditors that the ML model's decisions 
correlate logically with underlying consumer behavioral data.

Operational Exception Table (Table.png): A flat operational data grid integrated with an interactive 
dropdown control widget for Campaign_Decision. This allows fulfillment operations teams to seamlessly 
filter, audit, and extract the precise list of high-risk customer IDs to strip them from 
automated credit limit distribution runs.