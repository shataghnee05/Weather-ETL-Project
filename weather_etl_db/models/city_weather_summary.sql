{{ config(materialized='table') }}

/*
  City-Wise Weather Summary, Extremes, and Comparative Analysis
  Combines the latest observation per city (via window functions) with
  aggregate statistics, city rankings, and benchmark comparisons.
*/

WITH latest_city_reading AS (
    SELECT
        city,
        latitude,
        longitude,
        elevation,
        temperature AS latest_temperature,
        humidity AS latest_humidity,
        wind_speed AS latest_wind_speed,
        visibility_km AS latest_visibility_km,
        weather_condition AS latest_weather_condition,
        observation_date AS latest_observation_date,
        observation_time AS latest_observation_time,
        recorded_at AS latest_recorded_at,
        ROW_NUMBER() OVER (
            PARTITION BY city 
            ORDER BY recorded_at DESC, observation_date DESC, observation_time DESC
        ) AS rank_recency
    FROM {{ ref('cleaned_weather') }}
    WHERE temperature IS NOT NULL
),

city_aggregations AS (
    SELECT
        city,
        COUNT(*) AS total_observations,
        ROUND(AVG(temperature)::numeric, 2) AS avg_temperature,
        ROUND(MIN(temperature)::numeric, 2) AS min_temperature,
        ROUND(MAX(temperature)::numeric, 2) AS max_temperature,
        ROUND((MAX(temperature) - MIN(temperature))::numeric, 2) AS temperature_spread,
        ROUND(AVG(humidity)::numeric, 2) AS avg_humidity,
        ROUND(MIN(humidity)::numeric, 2) AS min_humidity,
        ROUND(MAX(humidity)::numeric, 2) AS max_humidity,
        ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed,
        ROUND(MAX(wind_speed)::numeric, 2) AS max_wind_speed,
        ROUND(AVG(visibility_km)::numeric, 2) AS avg_visibility_km,
        ROUND(MIN(visibility_km)::numeric, 2) AS min_visibility_km
    FROM {{ ref('cleaned_weather') }}
    WHERE temperature IS NOT NULL
    GROUP BY city
)

SELECT
    agg.city,
    l.latitude,
    l.longitude,
    l.elevation,
    
    -- Latest Weather Condition & Readings
    l.latest_weather_condition,
    l.latest_temperature,
    l.latest_humidity,
    l.latest_wind_speed,
    l.latest_visibility_km,
    l.latest_recorded_at,
    
    -- Historical / Aggregated Metrics
    agg.total_observations,
    agg.avg_temperature,
    agg.min_temperature,
    agg.max_temperature,
    agg.temperature_spread,
    agg.avg_humidity,
    agg.min_humidity,
    agg.max_humidity,
    agg.avg_wind_speed,
    agg.max_wind_speed,
    agg.avg_visibility_km,
    agg.min_visibility_km,

    -- Extreme Weather Rankings across Cities (1 = Top)
    DENSE_RANK() OVER (ORDER BY agg.max_temperature DESC) AS hottest_city_rank,
    DENSE_RANK() OVER (ORDER BY agg.min_temperature ASC) AS coldest_city_rank,
    DENSE_RANK() OVER (ORDER BY agg.max_wind_speed DESC) AS windiest_city_rank,
    DENSE_RANK() OVER (ORDER BY agg.avg_humidity DESC) AS highest_humidity_rank,
    DENSE_RANK() OVER (ORDER BY agg.avg_visibility_km ASC) AS lowest_visibility_rank,

    -- Comparative Benchmarking (Diff from National Average)
    ROUND((agg.avg_temperature - AVG(agg.avg_temperature) OVER())::numeric, 2) AS temp_diff_from_national_avg,
    ROUND((agg.avg_humidity - AVG(agg.avg_humidity) OVER())::numeric, 2) AS humidity_diff_from_national_avg,
    ROUND((agg.avg_wind_speed - AVG(agg.avg_wind_speed) OVER())::numeric, 2) AS wind_speed_diff_from_national_avg

FROM city_aggregations agg
JOIN latest_city_reading l 
  ON agg.city = l.city AND l.rank_recency = 1

