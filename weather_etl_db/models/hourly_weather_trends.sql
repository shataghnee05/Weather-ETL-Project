{{ config(materialized='table') }}

/*
  Hourly Weather Trends
  Tracks diurnal hourly cycles for temperature, humidity, and wind speed.
*/

SELECT
    observation_date,
    hour_of_day,
    COUNT(*) AS readings_count,
    ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
    ROUND(MIN(temperature)::numeric, 2) AS min_temperature,
    ROUND(MAX(temperature)::numeric, 2) AS max_temperature,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
    ROUND(AVG(visibility_km)::numeric, 2) AS avg_visibility_km
FROM {{ ref('cleaned_weather') }}
WHERE temperature IS NOT NULL
GROUP BY observation_date, hour_of_day
ORDER BY observation_date DESC, hour_of_day ASC

