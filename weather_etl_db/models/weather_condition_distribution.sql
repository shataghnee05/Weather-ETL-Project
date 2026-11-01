{{ config(materialized='table') }}

/*
  Weather Condition Distribution
  Computes occurrences, percentages, and frequency rankings for each weather condition.
*/

WITH condition_counts AS (
    SELECT
        weather_condition,
        COUNT(*) AS occurrence_count,
        COUNT(DISTINCT city) AS distinct_cities_affected,
        ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
        ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
        ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed
    FROM {{ ref('cleaned_weather') }}
    GROUP BY weather_condition
)

SELECT
    weather_condition,
    occurrence_count,
    ROUND(
        (occurrence_count * 100.0 / SUM(occurrence_count) OVER())::numeric,
        2
    ) AS percentage_of_total,
    DENSE_RANK() OVER (ORDER BY occurrence_count DESC) AS frequency_rank,
    distinct_cities_affected,
    avg_temperature,
    avg_humidity,
    avg_wind_speed
FROM condition_counts
ORDER BY occurrence_count DESC

