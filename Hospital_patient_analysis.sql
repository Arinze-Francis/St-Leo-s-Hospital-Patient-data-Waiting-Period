-- resetting mysql settings
SET SQL_SAFE_UPDATES = 0;
# your code SQL here
SET SQL_SAFE_UPDATES = 1;
SET GLOBAL sql_mode = '';

-- database normalization
CREATE TABLE time_table SELECT DISTINCT `Date` date,
    `entry.time` entry_time,
    `post.consultation.time` post_consu_time,
    `completion.time` completion_time FROM
    hospital_data;
SELECT 
    *
FROM
    time_table;

CREATE TABLE patient_table SELECT `patient.type` patient_type,
    `financial.class` financial_class,
    `doctor.type` doctor_type,
    `patient.id` patient_id,
    `entry.time` entry_time FROM
    patient_table;
SELECT 
    *
FROM
    patient_table;

CREATE TABLE revenue_tables SELECT `medication.revenue` Medic_revenue,
    `lab.cost` Lab_cost,
    `consultation.revenue` consultation_revenue,
    `patient.id` patient_id,
    `date` date FROM
    hospital_data;
SELECT 
    *
FROM
    revenue_tables;


-- data manipulation and transformation process so as to access the aggregate funtions
UPDATE revenue_tables 
SET 
    medic_revenue = REPLACE(REPLACE(medic_revenue, ',', ''),
        '-',
        0);
UPDATE revenue_tables 
SET 
    medic_revenue = SUBSTR(medic_revenue, 2);
SELECT 
    ROUND(SUM(medic_revenue), 2)
FROM
    revenue_tables;

UPDATE revenue_tables 
SET 
    lab_cost = REPLACE(lab_cost, '-', 0);

UPDATE revenue_tables 
SET 
    lab_cost = SUBSTR(lab_cost, 2);
UPDATE revenue_tables 
SET 
    lab_cost = REPLACE(lab_cost, '$', '');
SELECT 
    ROUND(SUM(lab_cost), 2)
FROM
    revenue_tables;

UPDATE revenue_tables 
SET 
    consultation_revenue = REPLACE(REPLACE(consultation_revenue, '$', ''),
        '',
        0);
SELECT 
    ROUND(SUM(consultation_revenue), 2)
FROM
    revenue_tables;

-- to check for duplicates
SELECT 
    patient_id, COUNT(patient_id) how_many
FROM
    patient_table
GROUP BY 1
HAVING how_many = 1
ORDER BY 2 DESC;

-- to know the number of unique patients that visited the hospital
SELECT 
    COUNT(DISTINCT patient_id)
FROM
    patient_table;

-- to know the total medication_revenue, lab_cost,  consultation_revenue
SELECT 
    ROUND(SUM(medic_revenue), 2) Medication_revenue,
    TRUNCATE(SUM(lab_cost), 2) Total_lab_cost,
    ROUND(SUM(consultation_revenue), 2) Total_consultation_revenue
FROM
    revenue_tables;


-- to know the financial class of patients that paid the most consultation FEES

SELECT DISTINCT
    p.financial_class,
    ROUND(SUM(r.consultation_revenue), 2) Consultation_revenue,
    COUNT(DISTINCT p.patient_id) Number_of_patients,
    ROUND(COUNT(DISTINCT p.patient_id) / ROUND(SUM(r.consultation_revenue), 2),
            3) * 100 'Patient_Consulation %'
FROM
    patient_table p
        LEFT JOIN
    revenue_tables r USING (patient_id)
GROUP BY 1
ORDER BY 4 DESC;

-- to know the doctor_type that brought us the most consultation revenue
SELECT DISTINCT
    p.doctor_type,
    COUNT(DISTINCT p.patient_id) Number_of_patients,
    ROUND(SUM(r.consultation_revenue), 2) Consultation_revenue,
    ROUND(COUNT(DISTINCT p.patient_id) / ROUND(SUM(r.consultation_revenue), 2),
            3) * 100 'doctor type_Consulation %'
FROM
    patient_table p
        LEFT JOIN
    revenue_tables r USING (patient_id)
GROUP BY 1
ORDER BY 3 DESC;

-- to know the patient_id that paid the most consultation revenue
WITH cte AS
(SELECT DISTINCT p.patient_id, 
ROUND(SUM(r.consultation_revenue),2) Consultation_revenue,
ROUND(SUM(r.medic_revenue),2) Medic_Revenue, 
TRUNCATE(SUM(r.lab_cost),2) lab_cost
FROM patient_table p
LEFT JOIN revenue_tables r
USING (patient_id)
GROUP BY 1
ORDER BY 2 desc)

SELECT patient_id, 
MAX(Consultation_revenue)
FROM cte;

-- to know the patient_id that paid the most medic revenue

WITH cte2 AS
(SELECT p.patient_id, 
ROUND(SUM(r.consultation_revenue),2) Consultation_revenue,
ROUND(SUM(r.medic_revenue),2) Medic_Revenue, 
TRUNCATE(SUM(r.lab_cost),2) lab_cost
FROM patient_table p
LEFT JOIN revenue_tables r
USING (patient_id)
GROUP BY 1
ORDER BY 3 DESC) 
SELECT patient_id, max(medic_revenue)
FROM cte2;

-- to select the top 5 dates with the most consultation revenue
SELECT 
    r.date dates,
    COUNT(DISTINCT r.patient_id) Number_of_patients,
    TRUNCATE(SUM(r.medic_revenue), 2) Medic_revenue,
    TRUNCATE(SUM(r.lab_cost), 2) Lab_cost,
    TRUNCATE(SUM(r.consultation_revenue), 2) Consultation_Revenue,
    COUNT(DISTINCT r.patient_id) / TRUNCATE(SUM(r.consultation_revenue), 2) * 100 Patient_consultation_revenue
FROM
    revenue_tables r
GROUP BY 1
ORDER BY 5 DESC
LIMIT 5;

-- to select the top 5 dates with the least consultation revenue
SELECT 
    r.date dates,
    COUNT(DISTINCT r.patient_id) Number_of_patients,
    TRUNCATE(SUM(r.medic_revenue), 2) Medic_revenue,
    TRUNCATE(SUM(r.lab_cost), 2) Lab_cost,
    TRUNCATE(SUM(r.consultation_revenue), 2) Consultation_Revenue,
    COUNT(DISTINCT r.patient_id) / TRUNCATE(SUM(r.consultation_revenue), 2) * 100 Patient_consultation_revenue
FROM
    revenue_tables r
GROUP BY 1
ORDER BY 5 ASC
LIMIT 5;

-- what financial class waited the most time?
SELECT 
    LOWER(p.financial_class) financial_class ,
    TIMEDIFF(t.post_consu_time, t.entry_time) wait_time
FROM
    patient_table p
        LEFT JOIN
    time_table t USING (entry_time)
GROUP BY 1
ORDER BY 2 DESC;


-- what days had the most wait period, limiting to the top 10
WITH cte5 AS 
(SELECT date, timediff(t.post_consu_time, t.entry_time) wait_time 
FROM time_table t
GROUP BY 1
ORDER BY 2 DESC)
SELECT date, wait_time
FROM cte5
LIMIT 10;


-- what day of the week had the most wait period 
SELECT 
    DAYNAME(date) name_of_day,
    TIMEDIFF(t.post_consu_time, t.entry_time) wait_time
FROM
    time_table t
GROUP BY 1
ORDER BY 2 DESC;

-- to know the doctor_type that had the most wait
SELECT 
    p.doctor_type doctor_type,
    TIMEDIFF(t.post_consu_time, t.entry_time) wait_time
FROM
    patient_table p
        INNER JOIN
    time_table t USING (entry_time)
GROUP BY 1
ORDER BY 2 DESC;

-- how many patients waited before been attended
WITH cte7 AS
(SELECT p.patient_id, COUNT(DISTINCT p.patient_id) patient_count, 
TIMEDIFF(t.post_consu_time, t.entry_time) wait_period
FROM patient_table p
INNER JOIN time_table t
USING (entry_time)
GROUP BY 1)

SELECT patient_id,  wait_period
FROM cte7
ORDER BY 2 DESC
LIMIT 10;

-- to know how much patients waited before the doctor can see them?
SELECT DISTINCT
    p.financial_class,
    ROUND(SUM(r.consultation_revenue), 2) Consultation_revenue,
    COUNT(DISTINCT p.patient_id) Number_of_patients,
    TIMEDIFF(t.post_consu_time, t.entry_time) wait_times
FROM
    patient_table p
        LEFT JOIN
    revenue_tables r USING (patient_id)
        LEFT JOIN
    time_table t USING (entry_time)
GROUP BY 1
ORDER BY 4 DESC;


