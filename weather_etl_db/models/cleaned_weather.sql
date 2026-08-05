SELECT 
city, latitude, longitude,
"Temperature" AS temp,
ROUND("Windspeed"::numeric , 2) AS ws,
"Humidity" AS humid,
"Visibility" AS Visibility,
"Weather_Conditions" AS wc,
CAST("Date" AS DATE) AS date,
REPLACE("Time", '-', ':') AS time
FROM weather_data
