{{ config(materialized='view') }}

/*
  Cleaned and Standardized Weather Staging Model
  Reads directly from the ingested `weather_data` table, standardizes column
  casing, formats timestamps, and casts numeric values.
*/

WITH raw_weather AS (
    SELECT
        city,
        latitude,
        longitude,
        "Elevation" AS elevation,
        "Timezone" AS timezone,
        "Temperature" AS temperature,
        ROUND("Windspeed"::numeric, 2) AS wind_speed,
        "Humidity" AS humidity,
        ROUND("Visibility"::numeric, 2) AS visibility_km,
        COALESCE("Weather_Conditions", 'Unknown') AS weather_condition,
        CAST("Date" AS DATE) AS observation_date,
        REPLACE("Time", '-', ':') AS observation_time,
        TO_TIMESTAMP(
            CAST("Date" AS text) || ' ' || REPLACE("Time", '-', ':'),
            'YYYY-MM-DD HH24:MI'
        ) AS recorded_at,
        EXTRACT(HOUR FROM TO_TIMESTAMP(
            CAST("Date" AS text) || ' ' || REPLACE("Time", '-', ':'),
            'YYYY-MM-DD HH24:MI'
        ))::integer AS hour_of_day
    FROM weather_data
)

SELECT * FROM raw_weather
