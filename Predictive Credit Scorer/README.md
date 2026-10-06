# Credit Limit Increase Risk Scorer (BigQuery ML and Looker Studio)

A BigQuery ML pipeline that trains a **logistic regression** model on synthetic historical default data, uses it to score a list of **7,000 credit limit increase campaign candidates**, and presents the decisions in a **Looker Studio** dashboard.

> **Note:** This is a learning and portfolio project. All data is synthetic, and the candidate data was designed to separate cleanly into "reject" and "accept" groups. The results therefore demonstrate that the pipeline works, not how good the model is. See [Results](#results) and [Limitations](#limitations).

---

## Project Overview

The project covers four stages:

1. **Data generation:** a historical table of customers with a default flag, and a table of campaign candidates.
2. **Model training:** a logistic regression model created and trained inside BigQuery using `CREATE MODEL`.
3. **Scoring:** a view that uses `ML.PREDICT` to estimate each candidate's probability of default and applies a decision cutoff.
4. **Reporting:** a four-page Looker Studio dashboard.

---

## Technical Stack

| Layer | Tool |
|---|---|
| Data warehouse and ML | Google BigQuery and BigQuery ML (logistic regression) |
| Techniques | `CREATE MODEL`, `ML.PREDICT`, `ML.EVALUATE`, `UNNEST`, CTEs, SQL views |
| Dashboard | Google Looker Studio |
| Data | 10,000 synthetic historical records and 7,000 synthetic candidates |

---

## Repository Contents

| File | Purpose |
|---|---|
| `Data_generation.sql` | Creates the historical and candidate tables, and contains later versions of the scoring view and an aggregated statistics view |
| `View_Script.sql` | Trains the model, runs `ML.EVALUATE` and creates an earlier version of the scoring view |
| `Historical_CLI_Data.png` | Preview of the historical table |
| `CLI_Candidates.png` | Preview of the candidate table |
| `Bar_Chart.png` | Dashboard page: scorecards and default probability chart |
| `Pie_Chart.png` | Dashboard page: accept and reject split |
| `Stacked_Barg_Graph.png` | Dashboard page: tenure by campaign decision |
| `Table.png` | Dashboard page: candidate table with a decision filter |

---

## Data

**Historical data (`Historical_CLI_Data`, 10,000 rows):** five equal-sized risk segments, from high risk to low risk, each with different average utilisation, income stability, monthly debt and tenure, and with default rates from 75% down to 3% (about 32% overall). The model learns from four features: `Current_Utilization_Rate`, `Income_Stability_Score`, `Total_Monthly_Debt_Obligations` and `Years_As_Customer`. The label is `Defaulted`.

**Candidates (`CLI_Candidates`, 7,000 rows):** four "rejection-prone" profiles of 1,000 each (high utilisation with low income stability, excessive debt, new customers with poor metrics, and multiple risk factors) and two "good customer" profiles of 1,500 each.

---

## Scoring Logic

1. `CREATE MODEL` trains a logistic regression model (`CLI_Risk_Model`) on the four features.
2. The scoring view (`vw_CLI_Campaign_Risk_Scoring`) calls `ML.PREDICT` on the candidates. Because the prediction returns a nested array of probabilities, a subquery over `UNNEST(predicted_Defaulted_probs)` picks out the probability for label 1 (default).
3. Candidates with a default probability **above 0.55** are marked `Reject (High Risk)`. All others are marked `ACCEPT`. The 55% cutoff is an illustrative choice.

**Run order:** create the two tables (the first two statements in `Data_generation.sql`), then run `View_Script.sql` to create the model, then create the views. `Data_generation.sql` also contains a later version of the scoring view (with profile columns, four-decimal probabilities and a rejection flag) and an aggregated statistics view, both of which depend on the model existing first. The dashboard screenshots were built from the earlier view in `View_Script.sql`, which rounds probabilities to two decimals.

---

## Dashboard

1. **Scorecards and probability chart (`Bar_Chart.png`):** 7.0K candidates appraised, 4.0K blocked and 3.0K approved, with a chart of candidate volume by default probability.
2. **Decision split (`Pie_Chart.png`):** 57.1% rejected and 42.9% accepted.
3. **Tenure by decision (`Stacked_Barg_Graph.png`):** candidate counts by years as customer and campaign decision.
4. **Candidate table (`Table.png`):** every candidate with their scores and a filter for the campaign decision.

The probability chart and the tenure chart treat continuous values as separate categories, so most records fall into a single "Others" bar. Both would need banded ranges (for example, probability in steps of 0.1 or tenure in year brackets) to show a useful distribution.

---

## Results

The model blocks about 4,000 of the 7,000 candidates (57.1%), which matches the four rejection-prone profiles, and approves the two good-customer profiles.

Because the candidate profiles were designed to be rejected or accepted, this outcome shows the pipeline works from end to end. It does not measure how accurate the model is.

---

## Model Evaluation

`View_Script.sql` includes an `ML.EVALUATE` query, which returns BigQuery's built-in evaluation metrics for the model. The results are not recorded in this repository.

---

## Limitations

* **Synthetic data:** results say nothing about how the model would perform on real customers.
* **Built-in outcome:** the candidate profiles were designed to separate cleanly, so the accept and reject split is largely predetermined.
* **No recorded evaluation:** no accuracy, precision, recall or ROC AUC figures are documented, and no separate test on candidate-style data was carried out.
* **Data outside the training range:** some candidate profiles lie beyond the ranges in the training data. For example, the "excessive debt" profile has monthly debt of roughly R6,000 to R10,000, while the training data stops at about R5,000.
* **Arbitrary cutoff:** the 55% threshold is not tied to business costs, policy or calibration.
* **Limited features:** the model uses only four features, with no review of fairness or explainability.
* **Real use would need more:** a production credit model would require proper validation, governance and review.
* **Scripts overlap:** two versions of the scoring view exist across the two SQL files, and the run order matters (see above).

---

## Possible Improvements

* Run `ML.EVALUATE` and record the metrics here, and test the model on data it was not trained on.
* Band the probabilities and tenure values so the dashboard charts show a distribution.
* Merge the two SQL files into a single script in run order.
* Choose the cutoff using an explicit trade-off between approved and rejected risk.
* Generate candidate data that overlaps more realistically with the historical data.

---

## How to Reproduce

1. Create a BigQuery dataset named `Credit_Risk`.
2. Run the two table-creation statements in `Data_generation.sql`.
3. Run the `CREATE MODEL` statement in `View_Script.sql` to train the model.
4. Create the scoring view and, optionally, the aggregated statistics view.
5. Connect the scoring view to Looker Studio and build the four report pages.

The generator uses random values, so exact figures vary slightly between runs.
