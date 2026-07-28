# Olist E-Commerce Sales, Retention & Delivery Analysis

An end-to-end data analytics project on the Olist Brazilian e-commerce marketplace dataset. It answers a set of real operational and executive questions a retail/marketplace business actually cares about — where is revenue concentrated, are customers coming back, is late delivery hurting reviews, and which categories/sellers are winning — by building a proper ETL pipeline into MySQL, running SQL analysis (joins, CTEs, window functions), and closing the loop with an EDA notebook and a Power BI dashboard.

## Dataset

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle). Nine raw CSVs covering customers, orders, order items, payments, reviews, products, sellers, geolocation, and product category name translations — about 99K orders in total.

## Tech Stack

Pulled directly from the imports/usage in the code, not guessed:

- **Python** — pandas, numpy
- **Database** — MySQL 8.0, accessed via SQLAlchemy (`create_engine`, `text`) and the `pymysql` driver
- **ETL** — `tqdm` (progress bars), Python's built-in `logging` and `time` modules
- **Analysis / visualization** — `matplotlib`, `seaborn`, inside a Jupyter notebook
- **BI** — Power BI (`Dashboard/Market Analysis.pbix`)
- **SQL** — joins, CTEs (`WITH`), and window functions (`DENSE_RANK`, `NTILE`, `LAG`, `SUM() OVER`) in `sql/analysis.sql`

> Note: `plotly` gets `pip install`-ed at the top of the notebook but isn't actually imported or used anywhere in it — safe to drop unless you're planning to use it.

There's currently no `requirements.txt` in the repo — see **Setup** below for the packages to install manually.

## Project Architecture

```
.
├── config.py            # DB connection settings (host/port/db/credentials) + raw data folder path
├── logger.py             # File logger -> logs/etl.log, INFO level, timestamped
├── exceptions.py         # Custom ETLError exception class
├── timer.py               # Small Timer utility (start/stop -> elapsed seconds)
├── database.py            # Builds the SQLAlchemy engine (mysql+pymysql, connection pooling)
├── table_mapping.py       # Dict mapping each raw CSV filename -> its target MySQL table
├── validation.py          # Prints row/column counts, duplicate count, null counts per table (diagnostic only)
├── data_cleaning.py       # Drops duplicate rows, empty strings -> NA, strips whitespace on text columns
├── loader.py               # Writes a cleaned dataframe to MySQL in 5,000-row chunks, confirms row count
├── report.py               # ETLReport — tracks tables loaded / rows imported / failures, prints summary
├── etl.py                  # Orchestrates the pipeline: read CSV -> validate -> clean -> load, for every table
├── sql/
│   ├── schema.sql          # DDL for all 9 tables, with primary keys + indexes on join/filter columns
│   └── analysis.sql        # 36 business-question SQL queries across 8 sections (KPIs, revenue, customers,
│                            #   products, sellers, delivery, reviews, advanced analytics/RFM/cohorts)
├── notebooks/
│   └── EDA.ipynb            # Pulls tables from MySQL, engineers delivery/delay/order-value features,
│                            #   ~25 business-question-driven charts with insights + recommendations
├── Dashboard/
│   ├── Market Analysis.pbix  # Power BI dashboard built on the same data
│   └── dashboard.png         # Dashboard screenshot
├── data/raw/                 # The 9 raw Olist CSVs
└── logs/etl.log               # Pipeline run history
```

The pipeline follows a single-responsibility split: each script does one job (connect, map, validate, clean, load, report), and `etl.py` just wires them together in a loop over `table_mapping.TABLE_MAPPING`.

## Setup Instructions

1. **Clone the repo and install MySQL 8.0** locally (or point at a remote instance you have access to).

2. **Install dependencies** (no `requirements.txt` yet, so install manually):
   ```bash
   pip install pandas numpy sqlalchemy pymysql tqdm matplotlib seaborn jupyter
   ```

3. **Create the database and schema:**
   ```bash
   mysql -u <your_user> -p -e "CREATE DATABASE ecommerce_analysis;"
   mysql -u <your_user> -p ecommerce_analysis < sql/schema.sql
   ```

4. **Set up credentials with a `.env` file (recommended — not how the code currently works, so this needs a small code change too):**

   `config.py` currently hardcodes the DB username/password/host/port directly in the file. Before pushing this anywhere public, it's worth switching to environment variables:

   - Install `python-dotenv`: `pip install python-dotenv`
   - Create a `.env` file in the project root (and add it to `.gitignore`):
     ```
     DB_USERNAME=root
     DB_PASSWORD=your_password_here
     DB_HOST=localhost
     DB_PORT=3306
     DB_NAME=ecommerce_analysis
     ```
   - Update `config.py` to load from it instead of hardcoding values, e.g.:
     ```python
     from urllib.parse import quote_plus
     from dotenv import load_dotenv
     import os

     load_dotenv()

     USERNAME = os.getenv("DB_USERNAME")
     PASSWORD = quote_plus(os.getenv("DB_PASSWORD"))
     HOST = os.getenv("DB_HOST")
     PORT = int(os.getenv("DB_PORT"))
     DATABASE = os.getenv("DB_NAME")
     DATA_FOLDER = "data/raw"
     ```
   *(This is a suggested improvement — the current `config.py` in the repo still has credentials hardcoded directly. Update it before you rely on the `.env` instructions above.)*

5. **Place the raw Olist CSVs** in `data/raw/` (download from the [Kaggle dataset page](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)) — the filenames need to match what's in `table_mapping.py` (`customers.csv`, `orders.csv`, `order_items.csv`, `payments.csv`, `order_reviews.csv`, `products.csv`, `sellers.csv`, `geolocation.csv`, `category_translation.csv`).

## How to Run

Run these in order from the project root:

```bash
# 1. Create the schema (if you haven't already)
mysql -u <your_user> -p ecommerce_analysis < sql/schema.sql

# 2. Run the ETL pipeline — reads CSVs, validates, cleans, loads into MySQL
python etl.py

# 3. Check the run summary printed to console, and logs/etl.log for details/errors

# 4. Run the SQL analysis queries against the loaded data (optional — can also
#    run individual queries as needed)
mysql -u <your_user> -p ecommerce_analysis < sql/analysis.sql

# 5. Open the EDA notebook for the full exploratory analysis and charts
jupyter notebook notebooks/EDA.ipynb

# 6. Open Dashboard/Market Analysis.pbix in Power BI Desktop for the dashboard view
```

## Key Findings

Pulled directly from the notebook's computed outputs:

- **Revenue is heavily state-concentrated** — São Paulo (SP) alone accounts for **$5,998,226.96** in total order value, more than 2.5x the next closest state (Rio de Janeiro at $2,144,379.69).
- **Delivery delays are real but not the norm** — of orders with a recorded delivery date, 92,906 arrived on time versus 6,535 late, so roughly **6.6% of delivered orders were late** — and later deliveries are associated with visibly lower review scores in the boxplot analysis.
- **Retention is a genuine gap** — the majority of customers in the dataset are one-time buyers rather than repeat purchasers (exact repeat-rate % isn't printed as a single figure in the notebook, but the pie chart and business insight both flag one-time buyers as the dominant group), which the notebook calls out directly as a loyalty-program opportunity.
- **Category performance varies a lot by dimension** — `health_beauty` leads on revenue ($1,258,681.34), `bed_bath_table` leads on units sold (11,115), `computers` leads on average price ($1,098.34), and `cds_dvds_musicals` has the highest average review score (4.64) — meaning "best category" depends entirely on which metric you're optimizing for.

## What's Next

- **Deeper cohort analysis** — `analysis.sql` already has a monthly cohort query (Q32), but it's not yet visualized as a retention curve/heatmap in the notebook or dashboard.
- **Finish the RFM segmentation logic** — the current `CASE` statement in Q33 only explicitly labels a few segments (Champions, Loyal, New, At-Risk High Value); most customers currently fall into a generic "Others" bucket and the segmentation could be made more granular.
- **Fill in the executive summary block** at the bottom of `analysis.sql` — it's still placeholder text, not the actual computed answers.
- **Add data quality gates** — right now `validation.py` only prints diagnostics; it doesn't actually stop a bad load. Turning some of those checks into real assertions would make the pipeline more trustworthy.
- **Add a requirements.txt / environment file** and basic tests for the ETL functions (`clean_dataframe`, `validate_dataframe`, `load_dataframe`) so the project is easier for someone else to pick up and trust.
- **Move credentials to `.env`** as outlined in Setup, if this repo is ever made public.
