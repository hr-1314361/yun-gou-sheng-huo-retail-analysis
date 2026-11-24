# Yungou Life — New Retail Enterprise Data Warehouse & Analytics Visualization System

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Hive](https://img.shields.io/badge/Hive-4.0.0-orange.svg)](https://hive.apache.org/)
[![Superset](https://img.shields.io/badge/Superset-3.1.3-green.svg)](https://superset.apache.org/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.67.0-red.svg)](https://streamlit.io/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)

An end-to-end enterprise data warehouse and business analytics system for Yungou Life, a new retail enterprise covering online (APP, Mini Program, PC) and offline stores across 20 provinces in China. The system covers the full pipeline: raw data ingestion → data quality assessment → cleaning → four-layer data warehouse → predictive modeling → AI-powered NL2SQL → multi-channel visualization → one-click Docker deployment.

---

## Architecture

```
Raw CSV → ODS → DWD (cleaned) → DWS (aggregated) → ADS (application)
                                                          │
                    ┌─────────────────────────────────────┼─────────────────────────────┐
                    ▼                                     ▼                             ▼
           Apache Superset                      ECharts Dashboard            Streamlit NL2SQL
         (BI Dashboard + Filters)          (1920×1080 Big Screen)        (Conversational Query)
                    │                                     │                             │
                    └─────────────────────────────────────┼─────────────────────────────┘
                                                          ▼
                                              Docker Compose (One-Click Deploy)
```

### Four-Layer Data Warehouse

| Layer | Description | Key Tables |
|---|---|---|
| **ODS** (Operational Data Store) | Raw data landing, no transformation | ods_order, ods_user, ods_product, ods_store, ods_pay |
| **DWD** (Data Warehouse Detail) | Cleaned detail facts (5 dirty data types fixed) | dwd_order, dwd_user, dwd_product, dwd_store, dwd_pay |
| **DWS** (Data Warehouse Summary) | Light aggregation by time × dimension | dws_sales_1d, dws_sales_category_1d, dws_sales_1m, ... |
| **ADS** (Application Data Service) | Business-facing result tables | ads_sales_daily, ads_category_topn, ads_region_sales, ... |

---

## Features

### 1. Data Quality & Cleaning
Five types of dirty data detection and repair with **100% fix rate**:
- Missing values → mean/median fill or `unknown` flag
- Duplicates → `ROW_NUMBER()` deduplication
- Abnormal values → truncation to valid range
- Inconsistent formats → unified date/phone/amount parsing
- Non-standard enums → standardized pay_type/channel/status mapping

### 2. Predictive Modeling
- GMV time-series forecasting with linear regression (**MAPE = 4.35%**, MAE = ¥85,749)
- Feature engineering: lag features, rolling statistics, cyclic encoding
- 7-day-ahead GMV prediction via recursive forecasting
- Model comparison: Linear Regression vs XGBoost (linear wins for this dataset)

### 3. NL2SQL (Natural Language to SQL)
- Powered by DeepSeek LLM with schema-aware prompt
- Three-level fallback: `llm+hive` → `llm+demo` → `demo` (always demonstrable)
- SQL safety guard: only `SELECT` allowed, write operations blocked
- Conversational interface in Streamlit with embedded ECharts charts

### 4. Multi-Channel Visualization
- **Apache Superset**: 5 charts (trend line, category bar, region map, payment pie, TopN table) with cross-filter dashboard
- **ECharts Big Screen**: 1920×1080, 5 chart types (line/bar/scatter/heatmap/map) with cross-chart linking (month × province × category 3D cube)
- **Streamlit**: chat-style query → auto SQL → table + chart rendering

### 5. One-Click Docker Deployment
- Orchestrated services: MySQL, Hive Metastore, HiveServer2, ClickHouse, Redis, Superset, Python App
- Health checks + ordered startup (`depends_on: condition: service_healthy`)
- Secrets injected via `.env` (no hardcoded credentials)
- Single command: `docker compose up -d`

### 6. Hive Query Optimization
- Partition pruning (365 → 30 partitions, **-91.8% scan**)
- Data skew handling (`skewindata` + salting)
- Bucketed Map Join

---

## Quick Start

### Prerequisites
- Docker Desktop 4.0+
- 8 GB RAM, 4 CPU cores
- DeepSeek API Key (for NL2SQL feature)

### Deployment

```bash
# 1. Clone the repository
git clone <repo-url>
cd yungou-life-analytics

# 2. Configure environment
cp docker/.env.example docker/.env
# Edit docker/.env: set passwords and DEEPSEEK_API_KEY

# 3. One-click start
cd docker
docker compose up -d --build

# 4. Verify services
docker compose ps
```

### Access Services

| Service | URL | Default Credentials |
|---|---|---|
| Apache Superset | http://localhost:8088 | admin / (set in `.env`) |
| Streamlit NL2SQL | http://localhost:8501 | — |
| ECharts Dashboard | http://localhost:8848 | — |
| HiveServer2 | jdbc:hive2://localhost:10000 | hive / (no password, NOSASL) |

---

## Tech Stack

| Category | Technology |
|---|---|
| Storage | Apache Hive 4.0.0, HDFS, Parquet |
| Metadata | MySQL 8.0 (Hive Metastore) |
| Ad-hoc Query | ClickHouse 24.3 |
| BI Visualization | Apache Superset 3.1.3 |
| Big Screen | Apache ECharts 5.5.0 |
| Conversational UI | Streamlit 1.67.0 |
| AI / LLM | DeepSeek API |
| Containerization | Docker, Docker Compose v2 |
| Language | Python 3.11, HiveQL, SQL |

---

## Project Structure

```
yungou-life-analytics/
├── sql/
│   ├── ods/            # ODS layer DDL & load scripts
│   ├── dwd/            # DWD layer DDL & ETL (cleaning)
│   ├── dws/            # DWS layer DDL & ETL (aggregation)
│   └── ads/            # ADS layer DDL & ETL (application metrics)
├── superset/           # Superset config, datasets, dashboard design
├── echarts/            # ECharts big screen (HTML/CSS/JS + data gen)
├── streamlit/          # Streamlit NL2SQL app
├── docker/             # Docker Compose + Dockerfiles
├── docs/               # Requirements, architecture, deployment, API guides
└── stress_test/        # Performance benchmarking scripts
```

---

## Documentation

| Document | Description |
|---|---|
| Requirements Doc | Business background, requirements, metric system |
| Data Quality Report | 5 dirty data types & fix rate |
| Architecture Design | Four-layer warehouse, fact/dimension design, tech stack |
| Deployment Manual | Environment, one-click deploy, troubleshooting |
| API Config Guide | DeepSeek, Hive, MySQL, ClickHouse, Superset config |

---

## Performance Benchmark

| Concurrency | Requests | Success Rate | QPS | P50 | P95 | P99 |
|---|---|---|---|---|---|---|
| 1 | 300 | 100% | 606.66 | 1.48ms | 2.83ms | 3.72ms |
| 5 | 300 | 100% | 1638.38 | 2.49ms | 5.12ms | 14.66ms |
| 10 | 300 | 100% | 992.39 | 9.56ms | 12.50ms | 22.63ms |
| 20 | 300 | 100% | 1077.66 | 17.52ms | 27.07ms | 33.97ms |

*Local SQLite baseline; Hive benchmark pending Docker environment.*

---

## Team

| Name | Role |
|---|---|
| 胡蕊 (Hu Rui) | Data Engineer & Full-Stack Developer |

---

## License

This project is licensed under the MIT License.

---

## Acknowledgments

- Apache Hive, Superset, ECharts, Streamlit communities
- DeepSeek for the LLM API
