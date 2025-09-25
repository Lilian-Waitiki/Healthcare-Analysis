-- Connect to database
USE hospital_db;

-- OBJECTIVE 1: ENCOUNTERS OVERVIEW
-- Overview of encounters table
SELECT * FROM encounters 
LIMIT 5;

-- 1a. How many total encounters occurred each year?
SELECT YEAR(START) AS year, COUNT(Id) AS total_encounters
FROM encounters
GROUP BY YEAR(START)
ORDER BY YEAR(START);

-- 1b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?
-- Using a CTE
WITH yearly AS (
    SELECT 
        YEAR(start) AS year,
        COUNT(id) AS year_encounters
    FROM encounters
    GROUP BY YEAR(start)
)
SELECT 
    YEAR(e.start) AS year,
    e.encounterclass,
    COUNT(e.id) AS total_encounters,
    y.year_encounters,
    ROUND(COUNT(e.id)/y.year_encounters * 100) AS pct
FROM encounters e
JOIN yearly y ON y.year = YEAR(e.start)
GROUP BY YEAR(e.start), e.encounterclass, y.year_encounters
ORDER BY year;


-- 1c. What percentage of encounters were over 24 hours versus under 24 hours?
WITH timeday AS (
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN stop > start + INTERVAL 24 HOUR THEN 1 ELSE 0 END) AS greater_24,
    SUM(CASE WHEN stop <= start + INTERVAL 24 HOUR THEN 1 ELSE 0 END) AS less_24
FROM encounters)
SELECT
	ROUND(greater_24/total * 100,2) AS pct_greater_24,
    ROUND(less_24/total * 100,2) AS pct_less_24
FROM timeday;

-- OBJECTIVE 2: COST & COVERAGE INSIGHTS
-- 2a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
WITH zero AS (SELECT COUNT(*) AS total_encounters,
	SUM(CASE WHEN PAYER_COVERAGE=0 THEN 1 ELSE 0 END) AS zero_payer
FROM encounters)
SELECT *, 
ROUND(zero_payer/total_encounters*100,2) AS pct_zero_payer
FROM zero;

-- 2b. What are the top 10 most frequent procedures performed and the average base cost for each?
SELECT 
	DESCRIPTION,
	COUNT(*) AS count_procedure,
    ROUND(AVG(BASE_COST),2) AS avg_base_cost
FROM procedures
GROUP BY DESCRIPTION
ORDER BY count_procedure DESC
LIMIT 10;

-- 2c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?
SELECT 
	DESCRIPTION,
    ROUND(AVG(BASE_COST),2) AS avg_base_cost,
    COUNT(*) AS count_procedure
FROM procedures
GROUP BY DESCRIPTION
ORDER BY avg_base_cost DESC
LIMIT 10;

-- 2d. What is the average total claim cost for encounters, broken down by payer?
SELECT 
	p.name AS payer_name,
    ROUND(AVG(e.TOTAL_CLAIM_COST),2) AS avg_total_claim_cost
FROM encounters AS e
	LEFT JOIN payers AS p
    ON e.PAYER = p.Id
GROUP BY p.name
ORDER BY avg_total_claim_cost DESC;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS
-- 3a. How many unique patients were admitted each quarter over time?

SELECT 
    YEAR(start) AS year,
    COUNT(DISTINCT CASE WHEN QUARTER(start) = 1 THEN patient END) AS Q1,
    COUNT(DISTINCT CASE WHEN QUARTER(start) = 2 THEN patient END) AS Q2,
    COUNT(DISTINCT CASE WHEN QUARTER(start) = 3 THEN patient END) AS Q3,
    COUNT(DISTINCT CASE WHEN QUARTER(start) = 4 THEN patient END) AS Q4,
	COUNT(DISTINCT patient) AS unique_year_total
FROM encounters
WHERE ENCOUNTERCLASS = 'inpatient'
GROUP BY YEAR(start)
ORDER BY year;

-- In each quarter, how many patients came in only that quarter (and never appeared in any other quarter of that year)
WITH patient_quarters AS ( -- Identify patient-quarter combination
    SELECT 
        patient,
        YEAR(start) AS yr,
        QUARTER(start) AS qtr
    FROM encounters
    WHERE ENCOUNTERCLASS = 'inpatient'
    GROUP BY patient, YEAR(start), QUARTER(start)
),
	patient_year_counts AS ( -- Count how many quarters each patient appears in per yea
    SELECT 
        patient,
        yr,
        COUNT(DISTINCT qtr) AS quarters_in_year
    FROM patient_quarters
    GROUP BY patient, yr
),
	exclusive_patients AS ( -- Keep only patients who appear in exactly 1 quarter per year
    SELECT pq.patient, pq.yr, pq.qtr
    FROM patient_quarters pq
    JOIN patient_year_counts pyc
      ON pq.patient = pyc.patient AND pq.yr = pyc.yr
    WHERE pyc.quarters_in_year = 1
)
SELECT -- Count them per quarter/year
    yr AS Year,
    SUM(CASE WHEN qtr = 1 THEN 1 ELSE 0 END) AS Q1_Exclusive,
    SUM(CASE WHEN qtr = 2 THEN 1 ELSE 0 END) AS Q2_Exclusive,
    SUM(CASE WHEN qtr = 3 THEN 1 ELSE 0 END) AS Q3_Exclusive,
    SUM(CASE WHEN qtr = 4 THEN 1 ELSE 0 END) AS Q4_Exclusive
FROM exclusive_patients
GROUP BY yr
ORDER BY yr;

-- 3b. How many patients were readmitted within 30 days of a previous encounter?
-- A readmission occurs when a patient is admitted (START) within 30 days of discharge (STOP) from a previous admission.
WITH ordered_encounters AS (
    SELECT 
        patient,
        start,
        stop,
        LAG(stop) OVER (PARTITION BY patient ORDER BY start) AS prev_stop
    FROM encounters
    WHERE ENCOUNTERCLASS = 'inpatient'   -- optional filter, usually applies to inpatient readmissions
)
SELECT 
    COUNT(DISTINCT patient) AS unique_patients_readmitted_30d,
    COUNT(*) AS total_readmissions_30d
FROM ordered_encounters
WHERE prev_stop IS NOT NULL
  AND TIMESTAMPDIFF(DAY, prev_stop, start) <= 30;


-- to show who they were (name and id)
WITH ordered_encounters AS (
    SELECT 
        patient AS patient_id,
        start,
        stop,
        LAG(stop) OVER (PARTITION BY patient ORDER BY start) AS prev_stop
    FROM encounters
    WHERE ENCOUNTERCLASS = 'inpatient'   -- filter only admitted patients if that's your definition
)
SELECT 
    oe.patient_id,
    CONCAT(pt.prefix, " ", pt.`first`," ", pt.`last`) AS patient_full_name,
    oe.prev_stop AS previous_discharge,
    oe.start AS readmission_start,
    TIMESTAMPDIFF(DAY, oe.prev_stop, oe.start) AS days_since_discharge
FROM ordered_encounters AS oe
LEFT JOIN patients AS pt
ON oe.patient_id = pt.id
WHERE prev_stop IS NOT NULL
  AND TIMESTAMPDIFF(DAY, prev_stop, start) <= 30
ORDER BY patient_id, readmission_start;

-- 3c. Which patients had the most readmissions?
WITH ordered_encounters AS (
    SELECT 
        e.patient,
        e.start,
        e.stop,
        LAG(e.stop) OVER (PARTITION BY e.patient ORDER BY e.start) AS prev_stop
    FROM encounters e
    WHERE e.ENCOUNTERCLASS = 'inpatient'
),
readmissions AS (
    SELECT 
        patient,
        start,
        prev_stop,
        TIMESTAMPDIFF(DAY, prev_stop, start) AS days_since_discharge
    FROM ordered_encounters
    WHERE prev_stop IS NOT NULL
      AND TIMESTAMPDIFF(DAY, prev_stop, start) <= 30
)
SELECT 
    r.patient as patient_id,
	CONCAT(p.prefix, " ", p.`first`," ", p.`last`) AS patient_full_name,
    -- p.name AS patient_name,
    COUNT(*) AS readmission_count,
    MIN(r.start) AS first_readmission,
    MAX(r.start) AS last_readmission
FROM readmissions r
JOIN patients p ON r.patient = p.id 
GROUP BY r.patient, patient_full_name
ORDER BY readmission_count DESC, patient_full_name;
