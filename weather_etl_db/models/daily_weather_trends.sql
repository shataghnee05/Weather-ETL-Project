{{ config(materialized='table') }}

/*
  Daily Weather Trends & Day-over-Day Changes
  Aggregates daily climate metrics and calculates changes over time
  using LAG() window functions.
*/

WITH daily_base AS (
    SELECT
        observation_date,
        COUNT(*) AS total_readings,
        COUNT(DISTINCT city) AS distinct_cities_recorded,
        ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
        ROUND(MIN(temperature)::numeric, 2) AS min_temperature,
        ROUND(MAX(temperature)::numeric, 2) AS max_temperature,
        ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
        ROUND(MIN(humidity)::numeric, 2) AS min_humidity,
        ROUND(MAX(humidity)::numeric, 2) AS max_humidity,
        ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
        ROUND(MAX(wind_speed)::numeric, 2) AS max_wind_speed,
        ROUND(AVG(visibility_km)::numeric, 2) AS avg_visibility_km
    FROM {{ ref('cleaned_weather') }}
    WHERE temperature IS NOT NULL
    GROUP BY observation_date
)

SELECT
    observation_date,
    total_readings,
    distinct_cities_recorded,
    avg_temperature,
    min_temperature,
    max_temperature,
    avg_humidity,
    min_humidity,
    max_humidity,
    avg_wind_speed,
    max_wind_speed,
    avg_visibility_km,

    -- Day-Over-Day (DoD) Historical Trend Changes via LAG()
    LAG(avg_temperature) OVER (ORDER BY observation_date) AS prev_day_avg_temp,
    ROUND((avg_temperature - LAG(avg_temperature) OVER (ORDER BY observation_date))::numeric, 2) AS temp_change_dod,
    ROUND((avg_humidity - LAG(avg_humidity) OVER (ORDER BY observation_date))::numeric, 2) AS humidity_change_dod,
    ROUND((avg_wind_speed - LAG(avg_wind_speed) OVER (ORDER BY observation_date))::numeric, 2) AS wind_speed_change_dod

FROM daily_base
ORDER BY observation_date DESC

