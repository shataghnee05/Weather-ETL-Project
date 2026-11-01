# Weatherly

An end-to-end ETL pipeline that extracts real-time weather data from the Open-Meteo API, transforms it using Python, loads it into PostgreSQL, models the data with dbt, and visualizes insights using Metabase. Apache Airflow orchestrates the complete workflow.

---

## Architecture

![Weather ETL Pipeline](assets/ETL_Pipeline.png)

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Orchestration | Apache Airflow |
| Programming | Python |
| API | Open-Meteo API |
| Database | PostgreSQL |
| Data Modeling | dbt |
| Dashboard | Metabase |
| Containerization | Docker |
| Data Processing | Pandas |
| Async Processing | aiohttp, asyncio |

---

## Project Structure

```text
Weather-ETL-Pipeline/
│
├── airflow/
├── analytics/
├── dags/
├── data/
├── src/
│   ├── extract.py
│   ├── transform.py
│   ├── load.py
│   └── utils.py
│
├── docker-compose.yml
├── requirements.txt
├── .gitignore
└── README.md
```

---



## Features

- Automated workflow orchestration with Apache Airflow
- Concurrent API requests using aiohttp and asyncio
- Weather data extraction from Open-Meteo API
- Data transformation and preprocessing with Pandas
- PostgreSQL data storage
- Data modeling using dbt
- Dashboard creation with Metabase
- Dockerized development environment

---

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/<your-username>/Weather-ETL-Pipeline.git
cd Weather-ETL-Pipeline
```

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Start Services

```bash
docker compose up -d
```

### Configure Environment Variables

Create a `.env` file.

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=weather_db
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
```

### Run Airflow

Open:

```
http://localhost:8080
```

Enable the DAG (`weather_ETL`) and trigger a pipeline run to extract, transform, and load live data into PostgreSQL.

### Run dbt Models

Once data is loaded into PostgreSQL, execute dbt to compile and materialize all analytical tables and views:

```bash
cd weather_etl_db
dbt run --profiles-dir .
dbt test --profiles-dir .
```

This builds the following analytical data models:
- **`cleaned_weather`** (View): Standardized staging model with typed columns and timestamps.
- **`weather_kpi_overview`** (Table): Core climate KPIs, temperature ranges, and aggregate averages.
- **`city_weather_summary`** (Table): Latest city readings, city aggregates, extreme weather ranks, and national benchmarks.
- **`daily_weather_trends`** (Table): Daily trends and Day-over-Day (DoD) climate changes via `LAG()`.
- **`hourly_weather_trends`** (Table): Diurnal 24-hour temperature and humidity cycles.
- **`weather_condition_distribution`** (Table): Condition counts, percentage share, and frequency rankings.
- **`city_condition_matrix`** (View): City-level distribution and percentages of weather conditions.
- **`data_quality_monitoring`** (View): Null counts, duplicate audit, freshness tracking, and completeness scores.

---

### Access Metabase Dashboards

Open Metabase in your browser:

```
http://localhost:3000
```

#### Connect Metabase to PostgreSQL:
- **Database Type:** PostgreSQL
- **Host:** `localhost` (or `127.0.0.1` when using host networking)
- **Port:** `5433` *(Mapped host port from `docker-compose.yml`)*
- **Database Name:** `weather_etl_db`
- **Username:** `shaty`
- **Password:** `shaty05`

#### Building the Weather Analytics & KPI Dashboard in Metabase:

1. **Weather Overview Section**:
   - Create **Number / KPI Cards** from `weather_kpi_overview`: Total Observations, Monitored Cities, Average Temp, Min/Max Temp, Average Humidity, and Average Wind Speed.
2. **City-Wise Analysis & Geography**:
   - Create a **Pin Map** using `latitude` and `longitude` from `city_weather_summary`.
   - Create a **Table or Bar Chart** showing `latest_temperature`, `latest_humidity`, and `latest_weather_condition` for each city.
3. **Time-Based Trends**:
   - Create a **Line Chart** from `daily_weather_trends` with `observation_date` on the X-axis and `avg_temperature`, `temp_change_dod` on the Y-axis.
   - Create an **Area / Line Chart** from `hourly_weather_trends` showing the 24-hour diurnal temperature curve.
4. **Weather Condition Distribution**:
   - Create a **Pie / Donut Chart** from `weather_condition_distribution` showing `percentage_of_total` grouped by `weather_condition`.
5. **Extreme Weather Leaderboards**:
   - Filter `city_weather_summary` where `hottest_city_rank <= 5` for **Top 5 Warmest Cities**.
   - Filter where `windiest_city_rank <= 5` for **Top 5 Windiest Cities**.
   - Filter where `lowest_visibility_rank <= 5` for **Top 5 Lowest Visibility Cities**.
6. **Comparative Analysis**:
   - Create a horizontal **Bar Chart** of `temp_diff_from_national_avg` and `humidity_diff_from_national_avg` from `city_weather_summary` to highlight cities warmer/colder than average.
7. **Data Quality & Pipeline Health**:
   - Create a **Progress Bar / Indicator** card using `data_completeness_percentage` from `data_quality_monitoring`.
   - Add a monitoring table showing `null_temperature_count`, `duplicate_records`, and `hours_since_latest_reading`.

---


## License

This project is licensed under the MIT License.