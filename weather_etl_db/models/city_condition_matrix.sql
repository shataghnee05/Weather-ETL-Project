{{ config(materialized='view') }}

/*
  City-Wise Weather Condition Matrix
  Breaks down weather condition occurrences per city with relative percentages.
*/

WITH city_condition_counts AS (
    SELECT
        city,
        weather_condition,
        COUNT(*) AS occurrence_count
    FROM {{ ref('cleaned_weather') }}
    GROUP BY city, weather_condition
)

SELECT
    city,
    weather_condition,
    occurrence_count,
    ROUND(
        (occurrence_count * 100.0 / SUM(occurrence_count) OVER (PARTITION BY city))::numeric,
        2
    ) AS city_condition_percentage
FROM city_condition_counts
ORDER BY city ASC, occurrence_count DESC

