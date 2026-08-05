{{config(materialized='table')}}
SELECT 
AVG(temp) AS avg_temp,
AVG(humid) AS avg_humidity,
AVG(Visibility) AS avg_visibility,
AVG(ws) AS avg_windspeed,
COUNT(DISTINCT city) AS cites,
MAX(date) AS latest_date,
MAX(time) AS latest_time
FROM {{ref('cleaned_weather')}}