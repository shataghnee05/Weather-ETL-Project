-- ==============================================================================
-- WEATHER ANALYTICS & KPI DASHBOARD SQL QUERIES
-- Designed for PostgreSQL and dbt models (`cleaned_weather` / `weather_data`)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. WEATHER OVERVIEW (High-level Executive KPIs)
-- dbt Model: weather_kpi_overview (Table)
-- ------------------------------------------------------------------------------
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
FROM cleaned_weather
WHERE temperature IS NOT NULL;


-- ------------------------------------------------------------------------------
-- 2. CITY-WISE ANALYSIS
-- dbt Model: city_weather_summary (Table)
-- ------------------------------------------------------------------------------
WITH latest_reading AS (
    SELECT
        city,
        weather_condition AS latest_weather_condition,
        temperature AS latest_temperature,
        humidity AS latest_humidity,
        wind_speed AS latest_wind_speed,
        visibility_km AS latest_visibility_km,
        recorded_at AS latest_recorded_at,
        ROW_NUMBER() OVER (
            PARTITION BY city 
            ORDER BY recorded_at DESC, observation_date DESC, observation_time DESC
        ) AS rn
    FROM cleaned_weather
    WHERE temperature IS NOT NULL
)
SELECT
    c.city,
    l.latest_weather_condition,
    l.latest_temperature,
    l.latest_humidity,
    l.latest_wind_speed,
    l.latest_visibility_km,
    l.latest_recorded_at,
    ROUND(AVG(c.temperature)::numeric, 2) AS avg_temperature,
    ROUND(MIN(c.temperature)::numeric, 2) AS min_temperature,
    ROUND(MAX(c.temperature)::numeric, 2) AS max_temperature,
    ROUND(AVG(c.humidity)::numeric, 2) AS avg_humidity,
    ROUND(AVG(c.wind_speed)::numeric, 2) AS avg_wind_speed,
    ROUND(AVG(c.visibility_km)::numeric, 2) AS avg_visibility_km
FROM cleaned_weather c
JOIN latest_reading l ON c.city = l.city AND l.rn = 1
WHERE c.temperature IS NOT NULL
GROUP BY 
    c.city, 
    l.latest_weather_condition, 
    l.latest_temperature, 
    l.latest_humidity, 
    l.latest_wind_speed, 
    l.latest_visibility_km, 
    l.latest_recorded_at
ORDER BY c.city ASC;


-- ------------------------------------------------------------------------------
-- 3. TIME-BASED ANALYSIS
-- dbt Models: daily_weather_trends, hourly_weather_trends (Tables)
-- ------------------------------------------------------------------------------

-- 3A. Daily Average, Min, Max Temperature, Humidity, Wind Speed & DoD Changes
WITH daily_metrics AS (
    SELECT
        observation_date,
        COUNT(*) AS daily_readings_count,
        ROUND(AVG(temperature)::numeric, 2) AS avg_daily_temp,
        ROUND(MIN(temperature)::numeric, 2) AS min_daily_temp,
        ROUND(MAX(temperature)::numeric, 2) AS max_daily_temp,
        ROUND(AVG(humidity)::numeric, 2) AS avg_daily_humidity,
        ROUND(AVG(wind_speed)::numeric, 2) AS avg_daily_wind_speed,
        ROUND(AVG(visibility_km)::numeric, 2) AS avg_daily_visibility
    FROM cleaned_weather
    WHERE temperature IS NOT NULL
    GROUP BY observation_date
)
SELECT
    observation_date,
    daily_readings_count,
    avg_daily_temp,
    min_daily_temp,
    max_daily_temp,
    avg_daily_humidity,
    avg_daily_wind_speed,
    avg_daily_visibility,
    -- Day-Over-Day (DoD) Historical Trend Changes via LAG()
    LAG(avg_daily_temp) OVER (ORDER BY observation_date) AS prev_day_temp,
    ROUND((avg_daily_temp - LAG(avg_daily_temp) OVER (ORDER BY observation_date))::numeric, 2) AS temp_change_dod,
    ROUND((avg_daily_humidity - LAG(avg_daily_humidity) OVER (ORDER BY observation_date))::numeric, 2) AS humidity_change_dod,
    ROUND((avg_daily_wind_speed - LAG(avg_daily_wind_speed) OVER (ORDER BY observation_date))::numeric, 2) AS wind_change_dod
FROM daily_metrics
ORDER BY observation_date DESC;

-- 3B. Hourly Temperature and Climate Trends (Diurnal Cycle)
SELECT
    observation_date,
    hour_of_day,
    COUNT(*) AS observations_count,
    ROUND(AVG(temperature)::numeric, 2) AS hourly_avg_temp,
    ROUND(MIN(temperature)::numeric, 2) AS hourly_min_temp,
    ROUND(MAX(temperature)::numeric, 2) AS hourly_max_temp,
    ROUND(AVG(humidity)::numeric, 2) AS hourly_avg_humidity,
    ROUND(AVG(wind_speed)::numeric, 2) AS hourly_avg_wind_speed
FROM cleaned_weather
WHERE temperature IS NOT NULL
GROUP BY observation_date, hour_of_day
ORDER BY observation_date DESC, hour_of_day ASC;


-- ------------------------------------------------------------------------------
-- 4. WEATHER CONDITION DISTRIBUTION
-- dbt Models: weather_condition_distribution (Table), city_condition_matrix (View)
-- ------------------------------------------------------------------------------

-- 4A. Count and Percentage of Each Condition with Frequency Ranking
SELECT
    weather_condition,
    COUNT(*) AS occurrence_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER())::numeric, 2) AS percentage_of_total,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS frequency_rank,
    COUNT(DISTINCT city) AS distinct_cities_affected,
    ROUND(AVG(temperature)::numeric, 2) AS avg_temp_during_condition,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity_during_condition
FROM cleaned_weather
GROUP BY weather_condition
ORDER BY occurrence_count DESC;

-- 4B. City-Wise Distribution of Weather Conditions
SELECT
    city,
    weather_condition,
    COUNT(*) AS condition_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY city))::numeric, 2) AS city_condition_percentage
FROM cleaned_weather
GROUP BY city, weather_condition
ORDER BY city ASC, condition_count DESC;


-- ------------------------------------------------------------------------------
-- 5. EXTREME WEATHER ANALYSIS
-- dbt Model: city_weather_summary (Table) / Direct Analytics
-- ------------------------------------------------------------------------------

-- 5A. Top 5 Warmest and Coldest Cities (Highest and Lowest Recorded Temperatures)
(
    SELECT 
        city, 
        'Warmest' AS extreme_category,
        MAX(temperature) AS recorded_value,
        '°C' AS unit
    FROM cleaned_weather
    WHERE temperature IS NOT NULL
    GROUP BY city
    ORDER BY recorded_value DESC
    LIMIT 5
)
UNION ALL
(
    SELECT 
        city, 
        'Coldest' AS extreme_category,
        MIN(temperature) AS recorded_value,
        '°C' AS unit
    FROM cleaned_weather
    WHERE temperature IS NOT NULL
    GROUP BY city
    ORDER BY recorded_value ASC
    LIMIT 5
)
ORDER BY extreme_category DESC, recorded_value DESC;

-- 5B. Top 5 Windiest Cities (Highest Recorded Wind Speeds)
SELECT 
    city, 
    MAX(wind_speed) AS max_wind_speed,
    ROUND(AVG(wind_speed)::numeric, 2) AS avg_wind_speed
FROM cleaned_weather
WHERE wind_speed IS NOT NULL
GROUP BY city
ORDER BY max_wind_speed DESC
LIMIT 5;

-- 5C. Top 5 Lowest Recorded Visibility (Fog/Smog/Adverse Weather Risk)
SELECT 
    city, 
    MIN(visibility_km) AS lowest_visibility_km,
    ROUND(AVG(visibility_km)::numeric, 2) AS avg_visibility_km
FROM cleaned_weather
WHERE visibility_km IS NOT NULL
GROUP BY city
ORDER BY lowest_visibility_km ASC
LIMIT 5;

-- 5D. Top 5 High-Humidity Locations
SELECT 
    city, 
    MAX(humidity) AS max_humidity_percentage,
    ROUND(AVG(humidity)::numeric, 2) AS avg_humidity_percentage
FROM cleaned_weather
WHERE humidity IS NOT NULL
GROUP BY city
ORDER BY max_humidity_percentage DESC, avg_humidity_percentage DESC
LIMIT 5;


-- ------------------------------------------------------------------------------
-- 6. COMPARATIVE ANALYSIS ACROSS CITIES
-- dbt Model: city_weather_summary (Table)
-- ------------------------------------------------------------------------------
SELECT
    city,
    ROUND(AVG(temperature)::numeric, 2) AS city_avg_temp,
    ROUND(AVG(humidity)::numeric, 2) AS city_avg_humidity,
    ROUND(AVG(wind_speed)::numeric, 2) AS city_avg_wind_speed,
    -- Benchmark against national averages
    ROUND((AVG(temperature) - AVG(AVG(temperature)) OVER())::numeric, 2) AS temp_diff_from_national_avg,
    ROUND((AVG(humidity) - AVG(AVG(humidity)) OVER())::numeric, 2) AS humidity_diff_from_national_avg,
    ROUND((AVG(wind_speed) - AVG(AVG(wind_speed)) OVER())::numeric, 2) AS wind_speed_diff_from_national_avg,
    -- Rank cities across key dimensions
    DENSE_RANK() OVER (ORDER BY AVG(temperature) DESC) AS temp_rank,
    DENSE_RANK() OVER (ORDER BY AVG(humidity) DESC) AS humidity_rank,
    DENSE_RANK() OVER (ORDER BY AVG(wind_speed) DESC) AS wind_rank
FROM cleaned_weather
WHERE temperature IS NOT NULL
GROUP BY city
ORDER BY temp_rank ASC;


-- ------------------------------------------------------------------------------
-- 7. DATA QUALITY AND MONITORING
-- dbt Model: data_quality_monitoring (View)
-- ------------------------------------------------------------------------------
WITH duplicate_audit AS (
    SELECT 
        COUNT(*) - COUNT(DISTINCT (city, observation_date, observation_time)) AS duplicate_records_count
    FROM cleaned_weather
),
freshness_audit AS (
    SELECT
        MIN(recorded_at) AS earliest_observation,
        MAX(recorded_at) AS latest_observation,
        ROUND(EXTRACT(EPOCH FROM (NOW() - MAX(recorded_at))) / 3600.0::numeric, 2) AS hours_since_latest_ingestion
    FROM cleaned_weather
)
SELECT
    COUNT(*) AS total_records_count,
    COUNT(DISTINCT city) AS distinct_cities_count,
    -- Missing / Null Audits
    COUNT(*) - COUNT(temperature) AS null_temperature_count,
    COUNT(*) - COUNT(humidity) AS null_humidity_count,
    COUNT(*) - COUNT(wind_speed) AS null_wind_speed_count,
    COUNT(*) - COUNT(visibility_km) AS null_visibility_count,
    SUM(CASE WHEN weather_condition = 'Unknown' THEN 1 ELSE 0 END) AS unknown_weather_condition_count,
    -- Data Completeness Percentage
    ROUND((COUNT(temperature) * 100.0 / NULLIF(COUNT(*), 0))::numeric, 2) AS data_completeness_pct,
    -- Duplicate Count
    d.duplicate_records_count,
    -- Ingestion Freshness
    f.earliest_observation,
    f.latest_observation,
    f.hours_since_latest_ingestion
FROM cleaned_weather
CROSS JOIN duplicate_audit d
CROSS JOIN freshness_audit f
GROUP BY 
    d.duplicate_records_count, 
    f.earliest_observation, 
    f.latest_observation, 
    f.hours_since_latest_ingestion;

