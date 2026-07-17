# FICA Section 28: Automated Anti-Money Laundering (AML) Split Deposit Triage Pipeline

## 📌 Project Overview
This project implements an end-to-end cloud data analytics pipeline designed to detect illicit financial structuring—commonly known as **"Smurfing"**—within a retail banking environment[cite: 5]. Under South African financial regulations, syndicates deliberately break down large, reportable cash sums into multiple micro-deposits to evade detection[cite: 5]. 

This pipeline models a synthetic 10,000-row retail banking transactional ledger, applies advanced window-function analytical logic in **Google BigQuery** to catch velocity-based anomalies over calendar dates, and visualizes true-positive risk profiles through a targeted **Looker Studio** forensic triage dashboard[cite: 5].

---

## ⚖️ South African Regulatory Framework (FICA)
In terms of **Section 28 of the Financial Intelligence Centre Act (FICA), Act 38 of 2001**, all accountable institutions in South Africa are legally mandated to file a **Cash Threshold Report (CTR)** for any physical cash transaction exceeding **R24,999.99**[cite: 5]. 

* **The Loophole Exploded:** Bad actors exploit this by executing multiple deposits under R10,000 across separate branches or intervals on the same day[cite: 5]. 
* **The Compliance Objective:** This pipeline moves past single-transaction monitoring[cite: 5]. It evaluates historical transactional velocity per unique customer per calendar day to identify structured smurfing patterns, protecting the institution from severe Financial Intelligence Centre (FIC) non-compliance penalties[cite: 5].

---

## 🛠️ Technical Stack
* **Data Warehouse / Engine:** Google BigQuery (SQL)[cite: 5]
* **Analytics Logic:** Advanced SQL Window Functions (`SUM() OVER`, `COUNT() OVER`)[cite: 5]
* **Business Intelligence / Visualization:** Google Looker Studio[cite: 5]
* **Data Volume:** 10,000 synthetic relational banking records spread across standard retail transaction categories (Cash Deposits, Cash Withdrawals, EFTs, Merchant Refunds)[cite: 5].

---

## 💾 Pipeline Logic & Core Architecture

The core intelligence of this pipeline resides in a dual-layered SQL database view layer (`Split Deposit Triage Script_2.sql`). Rather than filtering raw rows blindly (which triggers false positives for legitimate, high-volume cash businesses like spaza shops or filling stations), the engine runs a rigorous validation framework[cite: 5]:

1. **Dynamic Daily Partitioning:** The pipeline partitions the transaction ledger by unique customer ID and crops it into strict calendar-day boundaries using analytical window functions, aggregating total daily cash inflows dynamically.
2. **Multiplicity Verification:** The engine explicitly checks for the **Multiplicity Rule** (`Daily_Deposit_Count > 1`)[cite: 5]. An anomaly is only surfaced if a customer makes multiple cash injections on the same day, keeping individual deposit thresholds strictly beneath the automated R10,000 detection flags while collectively breaching the legal R24,999.99 limit.

---

## 📊 Forensic Reporting & Analytics Layer

The final layer transforms the analytical output of the pipeline view into an actionable, forensic dashboard inside **Looker Studio** for corporate compliance officers.

### 1. Triage Queue (`Table View.png`)
The primary monitoring interface surfaces structured, row-by-row transaction line items flagged by the pipeline. Rather than displaying detached raw totals, it couples each individual physical transaction amount side-by-side with the dynamically computed `Daily_Deposit_Total`. This interface allows analysts to immediately trace a suspect's full geographical movement across multiple branches and see precisely how individual transactions aggregated to breach the regulatory R24,999.99 limit.

### 2. Operational Volume Metrics (`Bar Graph.png`)
To support compliance resource allocation, the interface maps out total flagged event records distributed across physical banking channels. This layout highlights operational pressure points across branches, identifying locations that exhibit higher frequencies of structuring behavior.