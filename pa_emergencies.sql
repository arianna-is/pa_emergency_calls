SELECT * FROM calls.emergency;

-- Clean up the data: 
-- 1. Drop column e - all values in this column are 1
-- 2. Eliminate key words from column titles
-- 3. Change timeStamp datatype from text to datetime, and change the column name
-- 4. Split emergency column into two categories: cat and incident (currently in the form 'cat: incident')
-- 5. Extract station numbers from call information text field
-- 6. Fix erroneous latitude and longitude values
-- 7. Explore data

-- 1. ----------------------------------------------------
-- check that column e only has 1 as value for all rows
SELECT DISTINCT(e) FROM calls.emergency;
-- drop column e as it does not provide any additional information
ALTER TABLE calls.emergency
DROP COLUMN e;

-- 2. ----------------------------------------------------
-- column title in original data for the description was 'desc' which is used as a sorting keyword in SQL
-- change that title to info
ALTER TABLE calls.emergency
CHANGE COLUMN `desc` `info` VARCHAR(126); 

-- 3. ----------------------------------------------------
-- change dateTime column from text datatype to dateTime datatype
ALTER TABLE calls.emergency 
ADD COLUMN call_time DATETIME
	AFTER timeStamp;

UPDATE calls.emergency
SET call_time = str_to_date(timeStamp, '%Y-%m-%d %H:%i:%s');

ALTER TABLE calls.emergency
DROP COLUMN timeStamp;

-- check date range in dataset
SELECT MIN(call_time), MAX(call_time) FROM calls.emergency;


-- 4. ----------------------------------------------------
-- split emergency column from Catagory: Incident to two separate columns
ALTER TABLE calls.emergency
ADD cat VARCHAR(50) 
	AFTER title,
ADD incident VARCHAR(50)
	AFTER cat;

-- check code before inserting into columns
-- separate category (to be called cat)
SELECT LEFT(title, INSTR(title, ':')-1) FROM calls.emergency;
-- separate specific emergency name (to be called incident)
-- remove dashes that appear after some of the incident titles
SELECT REPLACE(SUBSTRING(title, INSTR(title, ':')+1), ' -', '') FROM calls.emergency;

-- fill new columns with their information
UPDATE calls.emergency
SET cat = LEFT(title, INSTR(title, ':')-1),
	incident = REPLACE(SUBSTRING(title, INSTR(title, ':')+1), ' -', '');

ALTER TABLE calls.emergency
DROP COLUMN title;




-- 5. ----------------------------------------------------
-- Exploring the info column to see how the station is presented 
SELECT info, cat FROM calls.emergency;
-- For traffic incidents, there is no station number
-- For Fire incidents, the station number is always given in the form 'Station:STA##'
-- For EMS incidents, the station number is always given in the form 'Station ###'

-- Run queries to extract station numbers and check code before creating new column
SELECT info, SUBSTRING_INDEX(SUBSTRING_INDEX(info,':',-1),';',1) FROM calls.emergency WHERE cat = 'Fire';
SELECT info, SUBSTRING_INDEX(SUBSTRING_INDEX(info,';',3),' ',-1) FROM calls.emergency WHERE cat = 'EMS';

-- create station column for station information
ALTER TABLE calls.emergency
ADD COLUMN station VARCHAR(10)
	AFTER ZIP; 

-- populate station column using case statement and extracting from info column
UPDATE calls.emergency
SET station = CASE WHEN cat = 'Fire' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(info,':',-1),';',1)
	WHEN cat = 'EMS' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(info,';',3),' ',-1)
    WHEN cat = 'Traffic' THEN 'N/A'
    END;
    
-- 6. ------------------------------------------------
-- Noted that some of the latitute and longitude data is innaccurately entered
-- There are locations where the longitude was entered as positive where it should be negative
-- There are locations where the longitude appears to have been divided by 100
SELECT * FROM calls.emergency WHERE lng > -1;
-- update lng column to accurately reflect locations within Montgomery County
UPDATE calls.emergency 
SET lng = -(lng) WHERE lng > 0;

UPDATE calls.emergency
SET lng = lng*100 WHERE lng > -1;

-- There are still two locations that are entered at lat 0, long 0 
SELECT * FROM calls.emergency WHERE info LIKE "RAMP EGYPT RD TO RT422  & EGYPT RD%";
-- Other calls with the same location description in info do have lat and long values
-- I will use those values to replace the missing values
UPDATE calls.emergency
SET lng = -75.4727228
WHERE lng = 0;

UPDATE calls.emergency
SET lat = 40.1369729
WHERE lat = 0;

-- collect data for map of call locations and types
SELECT cat, lat, lng
FROM calls.emergency
ORDER BY cat;



-- 7. ------------------------------------------------

-- explore new columns created by splitting the title into separate category and incident columns:
-- view all category names: EMS, Fire, Traffic
SELECT DISTINCT(cat) FROM calls.emergency;
-- view how many calls exist in each category
SELECT cat, COUNT(*) count FROM calls.emergency GROUP BY cat ORDER BY count DESC;
-- view all incident names; the rows returned will also show the number of possible incident names
SELECT DISTINCT(incident) FROM calls.emergency;
-- view what types of incidents have the highest occurance
SELECT incident, COUNT(*) count FROM calls.emergency
GROUP BY incident
ORDER BY count DESC;
-- view the same information in the context of which category it belongs to
SELECT cat, incident, COUNT(*) count FROM calls.emergency GROUP BY cat, incident ORDER BY count DESC;
-- Takeaways: 
-- Although most calls are for EMS, the highest frequency call is vehicle accident with a traffic response
-- Some incidents are categorized under a combination of fire, ems, and traffic - probably because both fire and EMS units are deployed 
-- This may lead to some double counting of these incidents


-- Examine average number of calls per hour by station- 
WITH daily_count AS (
	SELECT DATE(call_time) the_date, HOUR(call_time) the_hour, station, COUNT(*) num_calls
	FROM calls.emergency
	GROUP BY the_date, the_hour, station) 
SELECT the_hour, station, AVG(num_calls) avg_calls
FROM daily_count
WHERE station != 'N/A'
GROUP BY the_hour, station
ORDER BY avg_calls DESC;
-- Values ranged from 1 - 2 calls per hour. 
-- The only exception to this were the N/A stations, which were much higher (highest 11)
-- This N/A value represents calls that were dispatched under the Traffic category, which did not have associated station numbers
-- This means that these N/A stations represent buckets of more than one station, or are calls that are not associated with a station


-- Examine call trends:

-- Find average calls per hour accross the city to see busiest times of day
WITH daily_count AS (
	SELECT DATE(call_time) the_date, HOUR(call_time) the_hour, COUNT(*) num_calls
	FROM calls.emergency
	GROUP BY the_date, the_hour)
SELECT the_hour, ROUND(AVG(num_calls),1) avg_calls
FROM daily_count
GROUP BY the_hour
ORDER BY the_hour;

-- find average calls per hour grouped by category to see busiest times for different types of responses
WITH daily_count AS (
	SELECT DATE(call_time) the_date, HOUR(call_time) the_hour, cat, COUNT(*) num_calls
	FROM calls.emergency
	GROUP BY the_date, the_hour, cat)
SELECT cat, the_hour, ROUND(AVG(num_calls),2) avg_calls
FROM daily_count
GROUP BY cat, the_hour
ORDER BY cat, the_hour;

-- find monthly averages by category
WITH monthly_count AS (
	SELECT cat, MONTH(call_time) the_month, MONTHNAME(call_time) month_name, DATE(call_time) the_date, COUNT(*) num_calls
    FROM calls.emergency
    GROUP BY cat, the_month, month_name, the_date)
SELECT cat, the_month, month_name, ROUND(AVG(num_calls)) avg_calls
FROM monthly_count
GROUP BY cat, the_month, month_name
ORDER BY cat, the_month;

-- find average calls per day of the week
SELECT WEEKDAY(the_date) day_of_week, DAYNAME(the_date) day_name, ROUND(AVG(num_calls))
FROM 
(
	SELECT DATE(call_time) the_date, -- date
    COUNT(*) AS num_calls
    FROM calls.emergency
    GROUP BY the_date
) counts
GROUP BY day_of_week, day_name
ORDER BY day_of_week;

-- average number of daily calls per station
WITH daily_count AS (
SELECT DATE(call_time) the_date, cat, station, COUNT(*) num_calls
FROM calls.emergency
GROUP BY the_date, cat, station)
SELECT cat, station, WEEKDAY(the_date) AS day_of_week, DAYNAME(the_date) AS day_name, ROUND(AVG(num_calls)) avg_calls
FROM daily_count
GROUP BY day_of_week, day_name, cat, station
ORDER BY station, day_of_week;


-- find 5 busiest station with highest number of annual calls
SELECT cat, station, COUNT(*) num_calls
FROM calls.emergency
WHERE station != 'N/A'
GROUP BY cat, station
ORDER BY num_calls DESC;
-- all of the busiest stations are EMS stations
-- find busies fire stations with highest number of annual calls
SELECT cat, station, COUNT(*) num_calls
FROM calls.emergency
WHERE cat = 'Fire'
GROUP BY cat, station
ORDER BY num_calls DESC;

-- find stations with highest average calls per week for EMS
WITH weekly_calls AS (
	SELECT WEEK(call_time) the_week, station, COUNT(*) num_calls
    FROM calls.emergency
    WHERE cat = 'EMS'
    GROUP BY the_week, station)
SELECT station, ROUND(AVG(num_calls)) avg_weekly_calls
FROM weekly_calls
GROUP BY station
ORDER BY avg_weekly_calls DESC;

-- highest average calls per week for Fire stations
WITH weekly_calls AS (
	SELECT WEEK(call_time) the_week, station, COUNT(*) num_calls
    FROM calls.emergency
    WHERE cat = 'Fire'
    GROUP BY the_week, station)
SELECT station, ROUND(AVG(num_calls)) avg_weekly_calls
FROM weekly_calls
GROUP BY station
ORDER BY avg_weekly_calls DESC;

-- breakdown of dispatches by incident
SELECT cat, incident, count(*)
FROM calls.emergency
GROUP BY cat, incident;

-- total number of calls
SELECT COUNT(*) FROM calls.emergency;
