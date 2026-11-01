{{ config(materialized='table') }}

/*
  Weather Overview & Executive KPIs
  Aggregates overall climate KPIs across all monitored cities and observations.
*/

SELECT
    COUNT(*) AS total_weather_records,
    COUNT(DISTINCT city) AS total_monitored_cities,
    ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
    ROUND(MIN(temperature)::numeric, 2) AS min_temperature,
    ROUND(MAX(temperature)::numeric, 2) AS max_temperature,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(MIN(humidity)::numeric, 2) AS min_humidity,
    ROUND(MAX(humidity)::numeric, 2) AS max_humidity,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
    ROUND(MAX(wind_speed)::numeric, 2) AS max_wind_speed,
    ROUND(AVG(visibility_km)::numeric, 2) AS avg_visibility_km,
    ROUND(MIN(visibility_km)::numeric, 2) AS min_visibility_km,
    MIN(observation_date) AS earliest_date,
    MAX(observation_date) AS latest_date,
    MAX(recorded_at) AS latest_recorded_timestamp
FROM {{ ref('cleaned_weather') }}
WHERE temperature IS NOT NULL

