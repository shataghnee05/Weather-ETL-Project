{{ config(materialized='table') }}

/*
  KPI Cards (Backward Compatibility Model)
*/

SELECT 
    ROUND(AVG(temperature)::numeric, 2) AS avg_temp,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(visibility_km)::numeric, 2) AS avg_visibility,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_windspeed,
    COUNT(DISTINCT city) AS cites,
    MAX(observation_date) AS latest_date,
    MAX(observation_time) AS latest_time
FROM {{ ref('cleaned_weather') }}
WHERE temperature IS NOT NULL
