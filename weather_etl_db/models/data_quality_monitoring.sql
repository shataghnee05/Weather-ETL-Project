{{ config(materialized='view') }}

/*
  Data Quality, Completeness, and Pipeline Monitoring
  Provides data health metrics, missing value audits, duplicate detection,
  and freshness indicators.
*/

WITH duplicate_check AS (
    SELECT
        COUNT(*) - COUNT(DISTINCT (city, observation_date, observation_time)) AS duplicate_records
    FROM {{ ref('cleaned_weather') }}
),

freshness_metrics AS (
    SELECT
        MIN(recorded_at) AS earliest_ingested_reading,
        MAX(recorded_at) AS latest_ingested_reading,
        ROUND(
            EXTRACT(EPOCH FROM (NOW() - MAX(recorded_at))) / 3600.0::numeric,
            2
        ) AS hours_since_latest_reading
    FROM {{ ref('cleaned_weather') }}
)

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT city) AS distinct_cities_count,

    -- Missing / Null Audits
    COUNT(*) - COUNT(temperature) AS null_temperature_count,
    COUNT(*) - COUNT(humidity) AS null_humidity_count,
    COUNT(*) - COUNT(wind_speed) AS null_wind_speed_count,
    COUNT(*) - COUNT(visibility_km) AS null_visibility_count,
    SUM(CASE WHEN weather_condition = 'Unknown' THEN 1 ELSE 0 END) AS unknown_condition_count,

    -- Data Completeness Ratio
    ROUND(
        (COUNT(temperature) * 100.0 / NULLIF(COUNT(*), 0))::numeric,
        2
    ) AS data_completeness_percentage,

    -- Duplicates
    d.duplicate_records,

    -- Freshness
    f.earliest_ingested_reading,
    f.latest_ingested_reading,
    f.hours_since_latest_reading

FROM {{ ref('cleaned_weather') }}
CROSS JOIN duplicate_check d
CROSS JOIN freshness_metrics f
GROUP BY 
    d.duplicate_records, 
    f.earliest_ingested_reading, 
    f.latest_ingested_reading, 
    f.hours_since_latest_reading

