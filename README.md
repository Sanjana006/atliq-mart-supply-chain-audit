# 📦 AtliQ Mart — Supply Chain Performance Audit

<p align="center">
  <img src="https://img.shields.io/badge/PostgreSQL-14+-336791?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black"/>
  <img src="https://img.shields.io/badge/Python-Analysis-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/Jupyter-Notebook-F37626?style=for-the-badge&logo=jupyter&logoColor=white"/>
</p>

<br/>

> *"We started with a simple question: why are customers not renewing contracts?*
> *Six months of data, 14 SQL queries, and one Power BI dashboard later, the answer was clear.*
> *It wasn't one problem. It was a system-wide failure that nobody had measured properly."*

---

## 📌 Table of Contents

- [Business Context](#-business-context)
- [Dataset Overview](#-dataset-overview)
- [Project Structure](#-project-structure)
- [Tools & Technologies](#-tools--technologies)
- [Data Model & ER Diagram](#-data-model--er-diagram)
- [SQL Analysis — The Investigation](#-sql-analysis--the-investigation)
- [Power BI Dashboard — The Story](#-power-bi-dashboard--the-story)
- [Key Findings](#-key-findings)
- [Recommendations](#-recommendations)
- [My Assumptions](#-my-assumptions)
- [How to Run This Project](#-how-to-run-this-project)
- [Connect](#-connect)

---

## 🏢 Business Context

**AtliQ Mart** is an FMCG (Fast-Moving Consumer Goods) company operating across three cities in Gujarat, **Surat, Ahmedabad, and Vadodara**. They supply **18 products** across Dairy, Food, and Beverages to **35 retail customers**.

In early 2022, management flagged a critical concern: key retail customers were **not renewing their annual supply contracts**. The suspected reason: consistently poor delivery service levels. But nobody had quantified it. Nobody knew exactly where it was happening, which customers were most affected, or why.

This project was built to find out.

> **What is OTIF?**
> On-Time In-Full (OTIF) is the gold-standard KPI in FMCG supply chains. An order is OTIF = 1 only if it is delivered **both** on the agreed date **and** with the complete quantity ordered. Missing either condition = failure. Industry benchmark for FMCG: **85–95%.** AtliQ Mart's actual performance: **29%.**

---

## 📂 Dataset Overview

| Table | Description | Rows |
|-------|-------------|------|
| `dim_customers` | 35 retail customers with city mapping | 35 |
| `dim_products` | 18 products across 3 categories | 18 |
| `dim_targets_orders` | Individual OT%, IF%, OTIF% targets per customer | 35 |
| `dim_date` | Date dimension with week numbers | 183 |
| `fact_orders_aggregate` | Order-level OT, IF, OTIF binary flags | 31,729 |
| `fact_order_lines` | Product-level order quantity vs delivery quantity | 57,096 |

**Period:** March 2022 – August 2022 (6 months)  
**Cities:** Surat · Ahmedabad · Vadodara  
**Categories:** Dairy · Food · Beverages

---

## 🗂️ Project Structure

```
atliq-mart-supply-chain-audit/
│
├── C2 pdfs/                          ← Business knowledge & stakeholder context docs
│   ├── C2 Business Knowledge.pdf
│   ├── C2 Peter Pandey's Notes.pdf
│   └── C2 Stakeholder Chat_Business R...
│
├── data/                             ← Raw source data (6 CSV files)
│   ├── dim_customers.csv
│   ├── dim_date.csv
│   ├── dim_products.csv
│   ├── dim_targets_orders.csv
│   ├── fact_order_lines.csv
│   ├── fact_orders_aggregate.csv
│   ├── meta_data.txt                 ← Column definitions and data dictionary
│   └── metrics_list.xlsx             ← KPI definitions used in the project
│
├── images/                           ← Python-generated visualisations
│   └── city_category_heatmap.png
│
├── dashboards/                       ← Dashboard page screenshots
│   ├── page1_executive_summary.png
│   ├── page2_customer_risk.png
│   └── page3_product_diagnostics.png
│
├── Database.sql                      ← PostgreSQL table creation scripts
├── dax_measures.md                   ← All Power BI DAX measures documented
├── fmcg_dashboard.pbix               ← Power BI dashboard source file
├── fmcg_dashboard.pdf                ← Dashboard export for quick viewing
├── sql-analysis.ipynb                ← Jupyter notebook: 14 queries + insights
└── README.md
```

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| **PostgreSQL + pgAdmin** | Database setup, table creation, SQL query execution |
| **Jupyter Notebook** | SQL analysis via SQLAlchemy + pandas, documented with insights |
| **Python** (pandas, seaborn, matplotlib) | Data manipulation and heatmap visualisation |
| **Power BI Desktop** | 3-page interactive stakeholder dashboard |
| **DAX** | Calculated KPI measures in Power BI, documented in `dax_measures.md` |

> **Why SQL before Power BI?**
> Running the full analysis in SQL first means every visual in the dashboard is backed by a validated query not a drag-and-drop assumption. It also forces a deeper understanding of the data before committing to a dashboard structure.

> **Why are DAX measures in a separate file?**
> `dax_measures.md` documents every calculated measure used in Power BI, the formula, the purpose, and which page it appears on. This makes the project reproducible and reviewable without opening the `.pbix` file.

---

## 📐 Data Model & ER Diagram

The model uses a **Fact Constellation Schema** (galaxy schema) consisting of two fact tables sharing the same dimension tables. This is more advanced than a basic star schema and reflects real-world data warehousing practice where order-level and product-line-level analysis require separate fact tables.

```mermaid
erDiagram
    dim_date {
        date date PK
        string mmm_yy
        string week_no
    }

    dim_customers {
        int customer_id PK
        string customer_name
        string city
    }

    dim_products {
        bigint product_id PK
        string product_name
        string category
    }

    dim_targets_orders {
        int customer_id FK
        numeric ontime_target
        numeric infull_target
        numeric otif_target
    }

    fact_order_lines {
        string order_id FK
        int customer_id FK
        bigint product_id FK
        date order_placement_date FK
        int order_qty
        date agreed_delivery_date
        date actual_delivery_date
        int delivery_qty
        int in_full
        int on_time
        int on_time_in_full
    }

    fact_orders_aggregate {
        string order_id PK
        int customer_id FK
        date order_placement_date FK
        int on_time
        int in_full
        int otif
    }

    dim_customers ||--o{ dim_targets_orders : "customer_id"
    dim_customers ||--o{ fact_order_lines : "customer_id"
    dim_customers ||--o{ fact_orders_aggregate : "customer_id"
    dim_products ||--o{ fact_order_lines : "product_id"
    dim_date ||--o{ fact_order_lines : "order_placement_date"
    dim_date ||--o{ fact_orders_aggregate : "order_placement_date"
```

> **Schema Note:** `fact_orders_aggregate` is used for customer-level KPIs (OT%, IF%, OTIF%). `fact_order_lines` is used for product and quantity-level analysis (fill rate, undelivered qty, category performance). Keeping them separate avoids fan-out distortion in calculations, a common data modelling pitfall when mixing granularities.

---

## 🔍 SQL Analysis: The Investigation

All 14 queries were written in PostgreSQL and executed through Jupyter Notebook via SQLAlchemy. Each query targets a specific business question. The notebook (`sql-analysis.ipynb`) contains the full query code, output tables, and written insights for every single one.

---

### Query 1 : Overall KPI Snapshot
**Question:** What is the actual baseline performance across the entire business?

**Finding:** OTIF = **29%** against a target of ~66%. Failure rate = **71%**. OT% (59%) is higher than IF% (52.78%) — incomplete deliveries are a bigger problem than late ones.

> 71 out of every 100 orders are failing the customer. This single query confirmed the scale of the problem immediately.

---

### Query 2 : Monthly OTIF Trend
**Question:** Is performance improving, declining, or stuck?

**Finding:** OTIF stays flat between **28–31% across all 6 months** with no improvement trend. This rules out seasonality and confirms a structural, systemic problem.

---

### Query 3 : City-Wise Performance vs Target

**Finding:**

| City | Target | Actual | Gap |
|------|--------|--------|-----|
| Vadodara | 64.16% | 27.78% | **-36.38** |
| Ahmedabad | 65.62% | 29.33% | **-36.29** |
| Surat | 65.57% | 30.07% | **-35.50** |

All three cities show nearly identical gaps, this isn't a city-specific failure. Surat is marginally better but still critically below target.

---

### Query 4 : Customer-Level OTIF vs Individual Targets
**Finding:** All **35 customers** are **Critical Risk**, every single one is more than 20 percentage points below their individual target. The worst: Info Stores Surat at **-52.57 points**.

---

### Query 5 : Category-Level OTIF Analysis
**Finding:** Beverages has the lowest OTIF (47.55%), but all three categories sit within 1.3 points of each other. The problem is not category-specific, it's operational. Dairy carries the largest absolute quantity gap (360K units undelivered) due to high volume.

---

### Query 6 : Top 10 Products by Undelivered Quantity
**Finding:** All top 10 are **Dairy products**. AM Milk variants have the three highest undelivered quantities. OTIF remains below 50% for every high-demand product — pointing to a systemic procurement or planning failure in Dairy.

---

### Query 7 : Delivery Delay by City
**Finding:** Vadodara = 30.09% late (avg 1.69 days). Ahmedabad = 30.00% late (avg 1.70 days). Surat = 26.33% late (avg 1.67 days). The ~1.7 day delay being identical across all cities points to a **shared distribution infrastructure bottleneck**, not individual city issues.

---

### Query 8 : Weekly Pattern Analysis
**Finding:** OTIF stays between 27–31% **every single week** across 26 weeks. No end-of-month spikes, no recovery weeks. Continuous and structural.

---

### Query 9 : Volume vs Service Quality
**Finding:** The top 8 customers by order volume all have OTIF below 22%. Coolblue placed 2,437 orders (ranks 1 and 2 by volume) and received only 7–20% OTIF. This is a **negative service-volume correlation**, the opposite of what a healthy FMCG supply chain shows.

---

### Query 10 : OT vs IF Root Cause Split
**Finding:** IF% gap is consistently **larger than OT% gap** for most customers. Vijay Stores: IF gap = -49 points vs OT gap = -17 points. The dominant failure is **incomplete delivery** i.e not enough stock arriving. Two different root causes requiring two different fixes.

---

### Query 11 : Customers Below 10% OTIF
**Finding:** 5 customers have received less than 10% OTIF across 6 months. Acclaimed Stores Surat = **6.93%** receiving a successful delivery less than 1 in 15 times. These accounts are functionally lost without immediate escalation.

---

### Query 12 : Fill Rate Trend by Category and Month
**Finding:** Fill rate is **~96.5% consistently** across all categories and all 6 months. Products are being dispatched in near-full quantities. Yet OTIF is only 29%.

> This contradiction is the most important finding in the entire analysis. The supply isn't the problem — the execution is. Products are available. They're just not reaching customers on time and in complete order-level quantities.

---

### Query 14A : City × Category Failure Matrix
**Finding:** Vadodara + Dairy = **28.87% of ALL undelivered quantity** in the business. One city, one category, nearly a third of the total problem. The query also generates an `action_flag` column classifying each combination as Priority Fix / High Concern / Monitor / Stable — giving management a clear action sequence.

---

### Query 14B : Python Heatmap

The city × category OTIF matrix was visualised as a seaborn heatmap during the analysis phase.

![City × Category OTIF Heatmap](images/city_category_heatmap.png)

> Vadodara is consistently red across all categories. Surat is consistently greener. The 5-point gap between them is identical across all categories — pointing to a Vadodara warehouse or distribution issue, not a product-specific failure.

---

## 📊 Power BI Dashboard — The Story

The dashboard tells a **3-page investigative story**. Each page answers one question and leads to the next. This structure was intentional — not a collection of charts, but a narrative that builds from problem → people → root cause.

```
Page 1 — How severe is the problem?
              ↓
Page 2 — Which customers are most at risk?
              ↓
Page 3 — Why are deliveries failing?
```

---

### Page 1 — How Severe Is the Supply Chain Problem?

![Executive Summary](dashboards/page1_executive_summary.png)

**The opening page sets the scale of the problem.**

Five KPI cards tell the headline story immediately: **32K orders, 59% OT, 52.78% IF, 29.02% OTIF, -17.96 OTIF Gap.** Before a stakeholder reads a single chart, they know the situation is critical.

The monthly trend line is the most important visual on this page, a flat OTIF line at 29% running against a 66% target across all 6 months. No improvement. No dip. No recovery. Just a consistent gap that has been there since March and is still there in August.

The city bar chart confirms the problem is not location-specific, Surat (30), Ahmedabad (29), and Vadodara (28) all fall roughly 35–37 points below their targets.

The donut seals it: **71% of all orders are failing.**

> **Key message:** The supply chain has a systemic, company-wide service level failure that has not improved across 6 months.

---

### Page 2 — Which Customers Require Immediate Attention?

![Customer Risk Analysis](dashboards/page2_customer_risk.png)

**This page moves from scale to specificity : who exactly is affected and how urgently?**

Four KPI cards set the context: 35 total customers, **10 customers below 20% OTIF**, 35 customers below their individual targets, avg OTIF gap of -17.21. The middle stat is that 10 customers receiving less than 20% OTIF, is the alarm bell. These accounts receive a successful delivery less than 1 in 5 times.

The color-coded customer heatmap is the visual anchor. Red cells identify the worst customer-city combinations immediately, Acclaimed Stores Surat (6.93%), Coolblue Vadodara (7.14%), Lotus Mart Ahmedabad (7.97%) are visible without reading numbers.

The **Customer Priority Segmentation** scatter plot positions every customer by **Total Orders** (x-axis) and **OTIF %** (y-axis). Bubble size also encodes **Total Orders** i.e larger bubble = more orders. The dashed lines at ~2,200 orders and ~31% OTIF create four quadrants:

- **Top-left : Low volume, High OTIF (Stable):** A tight cluster of small bubbles sitting between 38–40% OTIF and ~1,500 orders. These are low-volume customers being served well, healthy relationships, but not strategically significant in terms of revenue scale.

- **Top-right : High volume, High OTIF (Protect):** The largest bubbles in the upper half land here, big accounts at 38–43% OTIF with 2,200–3,000 orders. These are your most valuable and best-served customers. Protecting this quadrant should be a top operational priority.

- **Bottom-left : Low volume, Low OTIF (Monitor):** A small cluster of tiny bubbles around 24–26% OTIF and ~1,600 orders. Small accounts receiving below-target service. Lower revenue impact, but worth watching for early warning signs.

- **Bottom-right : High volume, Low OTIF (Critical 🚨):** The biggest bubbles on the entire chart sit here having customers with 3,000–4,000 orders receiving only 14–18% OTIF. Maximum volume, minimum service level. These accounts represent the highest churn risk and require immediate supply chain intervention.

**The core insight:** bubble size grows as you move right but OTIF collapses in the same direction. Your largest customers are your most underserved, which is the most urgent signal on this page.

The Risk Distribution donut confirms: **65.71% of customers are High Risk.**

> **Key message:** Every customer is below target. High-volume accounts are receiving the worst service, maximum contract renewal risk exactly where revenue impact is highest.

---

### Page 3 : Why Are Deliveries Failing?

![Product Diagnostics](dashboards/page3_product_diagnostics.png)

**This page diagnoses the root cause : timing failure, quantity failure, or both?**

Three KPI cards open with the central contradiction: **458K units undelivered, 96.59% fill rate, Dairy as worst category.** A 96.59% fill rate looks healthy. OTIF Product Aware is 47.95%. That gap is the entire story.

The failure type donut breaks it down: **24.24% Only Late, 33.48% Only Incomplete, 42.28% Both Failed.** Nearly half of all failures fail on both dimensions simultaneously.

The Promised vs Delivered bar chart shows the quantity gap at product level. AM Milk variants have the largest gaps in absolute units. Every Dairy product shows a visible shortfall.

The city × category heatmap confirms Vadodara's consistent underperformance, red row across all three categories. Surat is noticeably greener.

The side-by-side 96.59% vs 47.95% cards with the explanation text is the most memorable element on this page:

> *"96.6% of ordered quantity arrives — yet only 48% of orders are OTIF. The remaining failure is almost entirely a timing problem disguised as a quantity problem."*

> **Key message:** The supply exists. The failure is in execution -> order-level completeness and scheduling. Vadodara + Dairy is the single biggest concentration of failure in the business.

---

## 💡 Key Findings

**1. OTIF is 29% against a 66% target and it hasn't moved in 6 months.**
The flat monthly trend rules out seasonality. This is structural.

**2. Every single customer is Critical Risk.**
All 35 accounts are more than 20 percentage points below their individual targets. There are no safe accounts.

**3. High-volume customers are getting the worst service.**
The top 8 accounts by order volume all have OTIF below 22%. AtliQ Mart has no service prioritisation system.

**4. Vadodara + Dairy = 29% of all undelivered quantity.**
One city, one category, nearly a third of the entire problem. Highest ROI fix available.

**5. The primary failure is quantity completeness, not just timing.**
IF% gap is consistently larger than OT% gap. Supply planning is failing before logistics even enters the picture.

**6. 42% of all failed orders fail on both dimensions i.e late AND incomplete.**
The most severe failure type dominates.

**7. Fill rate is 96.6% but OTIF is 29%.**
Products are available. The failure is in execution, order-level fulfilment and delivery scheduling.

---

## 🎯 Recommendations

**Fix Vadodara + Dairy First**
One city, one category, 29% of total failures. Highest fix-to-impact ratio. Investigate Vadodara's warehouse capacity, Dairy procurement volumes, and last-mile scheduling specifically.

**Implement a Service Prioritisation System**
High-volume customers are being treated the same as low-volume ones. Introduce a tiered service model where top accounts get priority fulfilment slots and proactive exception management.

**Fix the IF% Root Cause Before Addressing OT%**
Since IF% gap is larger than OT% gap, the problem is upstream in safety stock, demand forecasting, or procurement lead times. Fixing logistics routing won't solve this. Supply planning needs investigation first.

**Immediately Escalate the 10 Sub-20% OTIF Accounts**
Acclaimed Stores Surat (6.93%), Coolblue Vadodara (7.14%), Lotus Mart Ahmedabad (7.97%), Info Stores Surat (9.43%), Elite Mart Vadodara (9.72%) and 5 others. Direct management intervention required within 30–60 days.

**Study What Surat Is Doing Differently**
Surat's OTIF is consistently 2–3 points above Vadodara's across all categories. Something about Surat's operations works marginally better. Identifying and replicating it is a faster win than building new processes.

---

## 📝 My Assumptions

- An order where `delivery_qty < order_qty` is treated as In-Full = 0, even if the shortfall is small. In FMCG retail, a partial delivery breaks shelf planning for the customer regardless of size.
- `order_placement_date` was used as the primary date key across both fact tables for consistency.
- Weekly analysis starts from W10 (first full week of March 2022).
- OTIF Target in gap calculations uses each customer's individual target from `dim_targets_orders` not a company-wide average. This holds the business to its own specific commitments per customer.
- The threshold for "critical" customer risk was set at >20 points below target. In FMCG, a 5-point miss is operationally normal. A 20-point miss signals systemic failure requiring escalation.

---

## ⚙️ How to Run This Project

### Prerequisites
- PostgreSQL 14+ and pgAdmin
- Python 3.8+ : install dependencies:
```bash
pip install psycopg2-binary pandas sqlalchemy matplotlib seaborn jupyter
```
- Power BI Desktop (free from Microsoft)

---

### Step 1 : Set Up the Database

Open pgAdmin → create database:
```sql
CREATE DATABASE atliq_supply_chain;
```
Run `Database.sql` in the Query Tool to create all 6 tables.

---

### Step 2 : Import the CSVs

Right-click each table in pgAdmin → Import/Export Data → Import → select CSV from `/data/`.

Import in this order:
1. `dim_customers`
2. `dim_products`
3. `dim_targets_orders`
4. `dim_date`
5. `fact_orders_aggregate`
6. `fact_order_lines`

Verify row counts:
```sql
SELECT 'dim_customers' AS tbl, COUNT(*) FROM dim_customers UNION ALL
SELECT 'dim_products', COUNT(*) FROM dim_products UNION ALL
SELECT 'dim_targets_orders', COUNT(*) FROM dim_targets_orders UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date UNION ALL
SELECT 'fact_orders_aggregate', COUNT(*) FROM fact_orders_aggregate UNION ALL
SELECT 'fact_order_lines', COUNT(*) FROM fact_order_lines;
```

Expected: `35 / 18 / 35 / 183 / 31729 / 57096`

---

### Step 3 : Run the SQL Analysis

Open `sql-analysis.ipynb` in Jupyter. Update the connection string in Cell 1:
```python
engine = create_engine('postgresql+psycopg2://postgres:YOUR_PASSWORD@localhost:5432/atliq_supply_chain')
```
Run all cells in order. Each cell includes the query, output, and written insight.

---

### Step 4 : Open the Dashboard

Open `fmcg_dashboard.pbix` in Power BI Desktop. If prompted, reconnect data sources to your local `/data/` folder. For DAX reference while exploring, open `dax_measures.md` alongside.

---

## 👩‍💻 About the Author

### Sanjana Nathani
M.Sc. Data Science · Dhirubhai Ambani University, Gandhinagar *(Pursuing)*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/sanjana-nathani-26a42727b/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=flat&logo=github&logoColor=white)](https://github.com/Sanjana006)

---

<p align="center">
  <i>Built as a portfolio analytics project · PostgreSQL · Jupyter · Python · Power BI · DAX</i>
</p>