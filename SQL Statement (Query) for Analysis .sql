/*
1. Raw staging table
        ↓
2. Data type validation
        ↓
3. Clean / typed staging table
        ↓
4. Business-rule QA
        ↓
5. Geography classification / standardisation
        ↓
6. Dimension tables
   ├── DimGeography
   └── DimDate
        ↓
7. Fact / analytical base layer
        ↓
8. Subject-specific analytical views
   ├── vw_DiseaseBurden
   ├── vw_HealthcareStrain
   ├── vw_VaccinationAnalysis
   ├── vw_TestingAnalysis
   ├── vw_GovernmentResponse
   ├── vw_SocioeconomicVulnerability
   └── vw_DataCompleteness
        ↓
9. Summary / aggregation views
        ↓
10. Power BI
*/


CREATE DATABASE global_resilience;
GO


USE global_resilience;
GO

---FLAT RAW CSV DATA FILE WAS SUCCESSFULLY IMPORTED VIA THE IMPORT WIZARD--

---------------------------------------------------------------------------------
                -- INSPECT ROWS / DATA TYPES
---------------------------------------------------------------------------------
---Basic raw-table inspection
SELECT COUNT(*) AS Row_Count
FROM dbo.[health_data_raw];

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Health_data_raw'
ORDER BY ORDINAL_POSITION;

SELECT TOP (1000) *
FROM dbo.[health_data_raw];

SELECT
    country,
    date,
    COUNT(*) AS RecordCount
FROM dbo.[health_data_raw]
GROUP BY
    country,
    date
HAVING COUNT(*) > 1;

---------------------------------------------------------------------------------
 --Test the date conversion
SELECT TOP (100)
    date AS RawDate,
    TRY_CONVERT(date, NULLIF(date, ''), 101) AS ConvertedDate
FROM dbo.[health_data_raw];

SELECT DISTINCT
    date
FROM dbo.[health_data_raw]
WHERE NULLIF(LTRIM(RTRIM(date)), '') IS NOT NULL
  AND TRY_CONVERT(date, date, 101) IS NULL;

-------------------------------------------------------------------------------------
---Validate columns that should be whole numbers
SELECT
    country,
    date,
    total_cases   ---total_cases
FROM dbo.[health_data_raw]
WHERE NULLIF(TRIM(total_cases), '') IS NOT NULL
  AND TRY_CONVERT(BIGINT, total_cases) IS NULL;

SELECT
    country,
    date,
    population    ---- population
FROM dbo.[health_data_raw]
WHERE NULLIF(TRIM(population), '') IS NOT NULL
  AND TRY_CONVERT(BIGINT, population) IS NULL;

SELECT
    country,
    date,
    total_deaths   ----deaths
FROM dbo.[health_data_raw]
WHERE NULLIF(TRIM(total_deaths), '') IS NOT NULL
  AND TRY_CONVERT(BIGINT, total_deaths) IS NULL;
----------------------------------------------------------------------------------
---Validate decimal/rate columns
SELECT
    country,
    date,
    new_cases_smoothed
FROM dbo.[health_data_raw]  ----reproduction_rate
WHERE NULLIF(TRIM(new_cases_smoothed), '') IS NOT NULL
  AND TRY_CONVERT(FLOAT, new_cases_smoothed) IS NULL;

SELECT
    country,
    date,
    reproduction_rate   ---reproduction_rate
FROM dbo.[health_data_raw]
WHERE NULLIF(TRIM(reproduction_rate), '') IS NOT NULL
  AND TRY_CONVERT(FLOAT, reproduction_rate) IS NULL;

---------------------------------------------------------------------------------
                ----CREATE FINAL TYPED DATASET----
---------------------------------------------------------------------------------
CREATE TABLE dbo.health_data
(
    country                                   VARCHAR(100)    NOT NULL,
    date                                      DATE            NOT NULL,

    total_cases                               BIGINT          NULL,
    new_cases                                 BIGINT          NULL,
    new_cases_smoothed                        FLOAT           NULL,
    total_cases_per_million                   DECIMAL(20,8)   NULL,
    new_cases_per_million                     DECIMAL(20,8)   NULL,
    new_cases_smoothed_per_million            DECIMAL(20,8)   NULL,

    total_deaths                              BIGINT          NULL,
    new_deaths                                BIGINT          NULL,
    new_deaths_smoothed                       DECIMAL(20,8)   NULL,
    total_deaths_per_million                  DECIMAL(20,8)   NULL,
    new_deaths_per_million                    DECIMAL(20,8)   NULL,
    new_deaths_smoothed_per_million           DECIMAL(20,8)   NULL,

    excess_mortality                          DECIMAL(20,8)   NULL,
    excess_mortality_cumulative               DECIMAL(20,8)   NULL,
    excess_mortality_cumulative_absolute      DECIMAL(20,8)   NULL,
    excess_mortality_cumulative_per_million   DECIMAL(20,8)   NULL,

    hosp_patients                             BIGINT          NULL,
    hosp_patients_per_million                 DECIMAL(20,8)   NULL,
    weekly_hosp_admissions                    DECIMAL(20,8)   NULL,
    weekly_hosp_admissions_per_million        DECIMAL(20,8)   NULL,

    icu_patients                              BIGINT          NULL,
    icu_patients_per_million                  DECIMAL(20,8)   NULL,
    weekly_icu_admissions                     DECIMAL(20,8)   NULL,
    weekly_icu_admissions_per_million         DECIMAL(20,8)   NULL,

    stringency_index                          DECIMAL(20,8)   NULL,
    reproduction_rate                         FLOAT   NULL,

    total_tests                               BIGINT          NULL,
    new_tests                                 BIGINT          NULL,
    total_tests_per_thousand                  FLOAT           NULL,
    new_tests_per_thousand                    FLOAT           NULL,
    new_tests_smoothed                        FLOAT           NULL,
    new_tests_smoothed_per_thousand           FLOAT           NULL,
    positive_rate                             FLOAT           NULL,
    tests_per_case                            FLOAT           NULL,

    total_vaccinations                        BIGINT          NULL,
    people_vaccinated                         BIGINT          NULL,
    people_fully_vaccinated                   BIGINT          NULL,
    total_boosters                            BIGINT          NULL,
    new_vaccinations                          BIGINT          NULL,
    new_vaccinations_smoothed                 DECIMAL(20,8)   NULL,
    total_vaccinations_per_hundred            DECIMAL(20,8)   NULL,
    people_vaccinated_per_hundred             DECIMAL(20,8)   NULL,
    people_fully_vaccinated_per_hundred       DECIMAL(20,8)   NULL,
    total_boosters_per_hundred                DECIMAL(20,8)   NULL,
    new_vaccinations_smoothed_per_million     DECIMAL(20,8)   NULL,
    new_people_vaccinated_smoothed            DECIMAL(20,8)   NULL,
    new_people_vaccinated_smoothed_per_hundred DECIMAL(20,8)  NULL,

    code                                      VARCHAR(10)     NULL,
    continent                                 VARCHAR(50)     NULL,

    population                                BIGINT          NULL,
    population_density                        DECIMAL(20,8)   NULL,
    median_age                                DECIMAL(20,8)   NULL,
    life_expectancy                           DECIMAL(20,8)   NULL,
    gdp_per_capita                            DECIMAL(20,8)   NULL,
    extreme_poverty                           DECIMAL(20,8)   NULL,
    diabetes_prevalence                       DECIMAL(20,8)   NULL,
    handwashing_facilities                    DECIMAL(20,8)   NULL,
    hospital_beds_per_thousand                DECIMAL(20,8)   NULL,
    human_development_index                   DECIMAL(20,8)   NULL
);
SELECT * FROM dbo.health_data;   ----empty

------        Transform raw → clean-typed               
------------------------------------------------------------------------------------------
INSERT INTO dbo.[health_data]
SELECT
    TRIM(country),
    TRY_CONVERT(DATE, NULLIF(TRIM(date), ''), 101),

    TRY_CONVERT(BIGINT, NULLIF(TRIM(total_cases), '')),
    TRY_CONVERT(BIGINT, NULLIF(TRIM(new_cases), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(new_cases_smoothed), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(total_cases_per_million), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_cases_per_million), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_cases_smoothed_per_million), '')),

    TRY_CONVERT(BIGINT, NULLIF(TRIM(total_deaths), '')),
    TRY_CONVERT(BIGINT, NULLIF(TRIM(new_deaths), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_deaths_smoothed), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(total_deaths_per_million), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_deaths_per_million), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_deaths_smoothed_per_million), '')),

    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(excess_mortality), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(excess_mortality_cumulative), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(excess_mortality_cumulative_absolute), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(excess_mortality_cumulative_per_million), '')),

    TRY_CONVERT(BIGINT, NULLIF(TRIM(hosp_patients), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(hosp_patients_per_million), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(weekly_hosp_admissions), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(weekly_hosp_admissions_per_million), '')),

    TRY_CONVERT(BIGINT, NULLIF(TRIM(icu_patients), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(icu_patients_per_million), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(weekly_icu_admissions), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(weekly_icu_admissions_per_million), '')),

    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(stringency_index), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(reproduction_rate), '')),

    TRY_CONVERT(BIGINT, NULLIF(TRIM(total_tests), '')),
    TRY_CONVERT(BIGINT, NULLIF(TRIM(new_tests), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(total_tests_per_thousand), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(new_tests_per_thousand), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(new_tests_smoothed), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(new_tests_smoothed_per_thousand), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(positive_rate), '')),
    TRY_CONVERT(FLOAT, NULLIF(TRIM(tests_per_case), '')),

    TRY_CONVERT(BIGINT, NULLIF(TRIM(total_vaccinations), '')),
    TRY_CONVERT(BIGINT, NULLIF(TRIM(people_vaccinated), '')),
    TRY_CONVERT(BIGINT, NULLIF(TRIM(people_fully_vaccinated), '')),
    TRY_CONVERT(BIGINT, NULLIF(TRIM(total_boosters), '')),
    TRY_CONVERT(BIGINT, NULLIF(TRIM(new_vaccinations), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_vaccinations_smoothed), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(total_vaccinations_per_hundred), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(people_vaccinated_per_hundred), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(people_fully_vaccinated_per_hundred), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(total_boosters_per_hundred), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_vaccinations_smoothed_per_million), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_people_vaccinated_smoothed), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(new_people_vaccinated_smoothed_per_hundred), '')),

    NULLIF(TRIM(code), ''),
    NULLIF(TRIM(continent), ''),

    TRY_CONVERT(BIGINT, NULLIF(TRIM(population), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(population_density), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(median_age), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(life_expectancy), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(gdp_per_capita), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(extreme_poverty), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(diabetes_prevalence), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(handwashing_facilities), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(hospital_beds_per_thousand), '')),
    TRY_CONVERT(DECIMAL(20,8), NULLIF(TRIM(human_development_index), ''))

FROM dbo.[health_data]
WHERE NULLIF(TRIM(country), '') IS NOT NULL
  AND TRY_CONVERT(DATE, NULLIF(TRIM(date), ''), 101) IS NOT NULL;


-------------------------------------
----------DATA CLEANING--------------
-------------------------------------

-1. ---TABLE SCHEMA AND TABLE_NAME confirmation
SELECT TABLE_SCHEMA,TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

----TABLE CONFIRMATION
SELECT COUNT(*) AS total_rows
FROM dbo.health_data;

select*
from health_data;

---NO OF COLUMNS CONFIRMATION
SELECT COUNT(*) AS number_of_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'health_data';

--2. ---CHECK FOR MISSING/NULL values
---COUNTS ALL ROWS INCLUDING ROWS WHERE NEW_CASES IS NULL
SELECT COUNT(*) AS new_cases
from health_data;

-----ONLY COUNTS ROWS WHERE NEW-CASES HAS A VALUE
SELECT COUNT(COLUMN_NAME)
FROM health_data;
----WITH THE INFORMATION ABOVE WE CAME UP WITH A FORMULAE TO CALCULATE MISSING/NULL VALUES I.E TOTAL_ROWS-ROWS_CONTAINING A VALUE=MISSING VALUES.

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - Count(continent) AS  missing_continents,
     COUNT(*) - COUNT(population) AS missing_population,
      COUNT(*) - COUNT(excess_mortality) AS missing_excess_mortality,
       COUNT(*) - COUNT(hosp_patients) AS missing_hospital_patients,
        COUNT(*) - COUNT(weekly_hosp_admissions) AS missing_weekly_hosp_admissions,
         COUNT(*) - COUNT(icu_patients) AS missing_icu_patients,
          COUNT(*) - COUNT(weekly_icu_admissions) AS missing_weekly_icu_admissions,
           COUNT(*) - COUNT(stringency_index) AS missing_stringency_index,
            COUNT(*) - COUNT(reproduction_rate) AS missing_reproduction_rate,
             COUNT(*) - COUNT(total_tests) AS missing_total_tests,
              COUNT(*) - COUNT(new_tests) AS missing_new_tests,
               COUNT(*) - COUNT(tests_per_case) AS missing_tests_per_case,
                COUNT(*) - COUNT(total_vaccinations) AS missing_total_vaccinations,
                 COUNT(*) - COUNT(total_boosters) AS missing_total_boosters,
                  COUNT(*) - COUNT(new_vaccinations) AS missing_new_vaccinations,
                 
                   COUNT(*) - COUNT(total_cases) AS missing_total_cases,
                    COUNT(*) - COUNT(new_cases) AS missing_new_cases,
                    COUNT(*) - COUNT(total_deaths) AS missing_total_deaths,
                    COUNT(*) - COUNT(new_deaths) AS missing_new_deaths
                    FROM health_data;
                     
--3. ---HANDLING MISSING CONTINENT VALUES
UPDATE health_data
SET continent =
    CASE
        WHEN country IN (
            'England',
            'England and Wales',
            'Northern Ireland',
            'Scotland',
            'Wales'
        ) THEN 'Europe'

        WHEN country = 'Asia excl. China' THEN 'Asia'

        ELSE continent
    END
WHERE continent IS NULL
  AND country IN (
      'England',
      'England and Wales',
      'Northern Ireland',
      'Scotland',
      'Wales',
      'Asia excl. China'
  );
 ---QUERY TO VERIFY THAT THE UPDATE WORKED
  SELECT DISTINCT country, code, continent
FROM health_data
WHERE country IN (
    'England',
    'England and Wales',
    'Northern Ireland',
    'Scotland',
    'Wales',
    'Asia excl. China'
)
ORDER BY country;

--4. ---CHECK FOR DUPLICATES
SELECT
    country,
    date,
    COUNT(*) AS duplicate_count
FROM health_data
GROUP BY country, date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

--5. ---CHECK FOR DATA TYPES TO CONFIRM WHETHER THE CHANGES MADE DURING IMPORT WERE APPLIED

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'health_data'
ORDER BY ORDINAL_POSITION;

--6. ---CHECK FOR INCORRECT VALUES IN THE NUMBER OF CASES AND DEATHS COLUMNS FOR THEY CONTAIN COUNTS THEREFORE THEY SHOULD NOT HAVE A -VE VALUE

SELECT *
FROM health_data
WHERE total_cases < 0
   OR new_cases < 0;

SELECT *
FROM health_data
WHERE total_deaths < 0
   OR new_deaths < 0;

-------------------------------------------------------------------------------------------------------------------------
------- -- -------------------------------------- CREATING TABLES-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
/*---Because the dataset contained both individual countries and aggregate entities such as continent and regional groupings.
-We created a country directory and country profile*/
---1) --country directory
CREATE TABLE Country_directory (
    country_id INT IDENTITY(1,1) PRIMARY KEY,
    country VARCHAR(150) NOT NULL,
    code VARCHAR(10) NULL,
    continent VARCHAR(50) NULL
);
GO
----POPULATE TABLE----------
INSERT INTO Country_directory(country, code, continent)
SELECT DISTINCT
    country,
    code,
    continent
FROM health_data
WHERE country IS NOT NULL;
GO
---TABLE CONFIRMATION
SELECT *
FROM Country_directory
ORDER BY country;

USE global_resilience;
GO
---2) -- country profile
CREATE TABLE country_profile (
    profile_id INT IDENTITY(1,1) PRIMARY KEY,
    country_id INT NOT NULL,
    population BIGINT NULL,
    population_density DECIMAL(18,4) NULL,
    median_age DECIMAL(10,2) NULL,
    life_expectancy DECIMAL(10,2) NULL,
    gdp_per_capita DECIMAL(18,2) NULL,
    extreme_poverty DECIMAL(10,2) NULL,
    diabetes_prevalence DECIMAL(10,2) NULL,
    handwashing_facilities DECIMAL(10,2) NULL,
    hospital_beds_per_thousand DECIMAL(10,4) NULL,
    human_development_index DECIMAL(10,4) NULL,

    CONSTRAINT FK_country_profile_country
        FOREIGN KEY (country_id)
        REFERENCES Country_directory(country_id)
);
GO

----POPULATE TABLE----------
INSERT INTO country_profile (
    country_id,
    population,
    population_density,
    median_age,
    life_expectancy,
    gdp_per_capita,
    extreme_poverty,
    diabetes_prevalence,
    handwashing_facilities,
    hospital_beds_per_thousand,
    human_development_index
)
SELECT DISTINCT
    c.country_id,
    s.population,
    s.population_density,
    s.median_age,
    s.life_expectancy,
    s.gdp_per_capita,
    s.extreme_poverty,
    s.diabetes_prevalence,
    s.handwashing_facilities,
    s.hospital_beds_per_thousand,
    s.human_development_index
FROM health_data AS s
INNER JOIN Country_directory c
    ON s.country = c.country
WHERE s.population IS NOT NULL;
GO

SELECT *
FROM country_profile
ORDER BY country_id;

---3)-- health metrics
USE global_resilience;
GO

CREATE TABLE health_metrics (
    metric_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    country_id INT NOT NULL,
    date DATE NOT NULL,

    total_cases BIGINT NULL,
    new_cases BIGINT NULL,
    new_cases_smoothed DECIMAL(18,2) NULL,

    total_cases_per_million DECIMAL(18,4) NULL,
    new_cases_per_million DECIMAL(18,4) NULL,
    new_cases_smoothed_per_million DECIMAL(18,4) NULL,

    total_deaths BIGINT NULL,
    new_deaths BIGINT NULL,
    new_deaths_smoothed DECIMAL(18,2) NULL,

    total_deaths_per_million DECIMAL(18,4) NULL,
    new_deaths_per_million DECIMAL(18,4) NULL,
    new_deaths_smoothed_per_million DECIMAL(18,4) NULL,

    reproduction_rate DECIMAL(10,4) NULL,

    excess_mortality DECIMAL(18,4) NULL,
    excess_mortality_cumulative DECIMAL(18,4) NULL,
    excess_mortality_cumulative_absolute BIGINT NULL,
    excess_mortality_cumulative_per_million DECIMAL(18,4) NULL,

    stringency_index DECIMAL(10,4) NULL,

    CONSTRAINT FK_health_metrics_country
        FOREIGN KEY (country_id)
        REFERENCES Country_directory(country_id)
);
GO
---POPULATE TABLE----
INSERT INTO health_metrics (
    country_id,
    date,
    total_cases,
    new_cases,
    new_cases_smoothed,
    total_cases_per_million,
    new_cases_per_million,
    new_cases_smoothed_per_million,
    total_deaths,
    new_deaths,
    new_deaths_smoothed,
    total_deaths_per_million,
    new_deaths_per_million,
    new_deaths_smoothed_per_million,
    reproduction_rate,
    excess_mortality,
    excess_mortality_cumulative,
    excess_mortality_cumulative_absolute,
    excess_mortality_cumulative_per_million,
    stringency_index
)
SELECT
    c.country_id,
    s.date,
    s.total_cases,
    s.new_cases,
    s.new_cases_smoothed,
    s.total_cases_per_million,
    s.new_cases_per_million,
    s.new_cases_smoothed_per_million,
    s.total_deaths,
    s.new_deaths,
    s.new_deaths_smoothed,
    s.total_deaths_per_million,
    s.new_deaths_per_million,
    s.new_deaths_smoothed_per_million,
    s.reproduction_rate,
    s.excess_mortality,
    s.excess_mortality_cumulative,
    s.excess_mortality_cumulative_absolute,
    s.excess_mortality_cumulative_per_million,
    s.stringency_index
FROM health_data s
INNER JOIN Country_directory c
    ON s.country = c.country
WHERE s.date IS NOT NULL;
GO
---CONFIRMATION
SELECT COUNT(*) AS total_health_records
FROM health_metrics;

SELECT TOP 20 *
FROM health_metrics
ORDER BY date, country_id;

---RELATIONSHIP CONFIRMATION
SELECT TOP 20
    c.country,
    c.code,
    c.continent,
    h.date,
    h.total_cases,
    h.new_cases,
    h.total_deaths,
    h.reproduction_rate
FROM health_metrics h
INNER JOIN Country_directory c
    ON h.country_id = c.country_id
ORDER BY h.date, c.country;

--4) -- healthcare capacity
USE global_resilience;
GO

CREATE TABLE healthcare_capacity (
    capacity_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    country_id INT NOT NULL,
    date DATE NOT NULL,

    hosp_patients BIGINT NULL,
    hosp_patients_per_million DECIMAL(18,4) NULL,

    weekly_hosp_admissions BIGINT NULL,
    weekly_hosp_admissions_per_million DECIMAL(18,4) NULL,

    icu_patients BIGINT NULL,
    icu_patients_per_million DECIMAL(18,4) NULL,

    weekly_icu_admissions BIGINT NULL,
    weekly_icu_admissions_per_million DECIMAL(18,4) NULL,

    CONSTRAINT FK_healthcare_capacity_country
        FOREIGN KEY (country_id)
        REFERENCES Country_directory(country_id)
);
GO
---POPULATE TABLE
INSERT INTO healthcare_capacity (
    country_id,
    date,
    hosp_patients,
    hosp_patients_per_million,
    weekly_hosp_admissions,
    weekly_hosp_admissions_per_million,
    icu_patients,
    icu_patients_per_million,
    weekly_icu_admissions,
    weekly_icu_admissions_per_million
)
SELECT
    c.country_id,
    s.date,
    s.hosp_patients,
    s.hosp_patients_per_million,
    s.weekly_hosp_admissions,
    s.weekly_hosp_admissions_per_million,
    s.icu_patients,
    s.icu_patients_per_million,
    s.weekly_icu_admissions,
    s.weekly_icu_admissions_per_million
FROM health_data s
INNER JOIN Country_directory c
    ON s.country = c.country
WHERE s.date IS NOT NULL;
GO
---CHECK--
SELECT TOP 20 *
FROM healthcare_capacity
ORDER BY date, country_id;
---RELATIONSHIP CONFIRMATION
SELECT TOP 20
    c.country,
    c.code,
    c.continent,
    h.date,
    h.hosp_patients,
    h.hosp_patients_per_million,
    h.weekly_hosp_admissions,
    h.icu_patients,
    h.icu_patients_per_million,
    h.weekly_icu_admissions
FROM healthcare_capacity h
INNER JOIN Country_directory c
    ON h.country_id = c.country_id
ORDER BY h.date, c.country;

--5)--- testing-vaccination_metrics
USE global_resilience;
GO

CREATE TABLE testing_vaccination_metrics (
    record_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    country_id INT NOT NULL,
    date DATE NOT NULL,

    total_tests BIGINT NULL,
    new_tests BIGINT NULL,
    total_tests_per_thousand DECIMAL(18,4) NULL,
    new_tests_per_thousand DECIMAL(18,4) NULL,
    new_tests_smoothed BIGINT NULL,
    new_tests_smoothed_per_thousand DECIMAL(18,4) NULL,
    positive_rate DECIMAL(10,4) NULL,
    tests_per_case DECIMAL(18,4) NULL,

    total_vaccinations BIGINT NULL,
    people_vaccinated BIGINT NULL,
    people_fully_vaccinated BIGINT NULL,
    total_boosters BIGINT NULL,
    new_vaccinations BIGINT NULL,
    new_vaccinations_smoothed BIGINT NULL,

    total_vaccinations_per_hundred DECIMAL(18,4) NULL,
    people_vaccinated_per_hundred DECIMAL(18,4) NULL,
    people_fully_vaccinated_per_hundred DECIMAL(18,4) NULL,
    total_boosters_per_hundred DECIMAL(18,4) NULL,

    new_vaccinations_smoothed_per_million DECIMAL(18,4) NULL,
    new_people_vaccinated_smoothed BIGINT NULL,
    new_people_vaccinated_smoothed_per_hundred DECIMAL(18,4) NULL,

    CONSTRAINT FK_testing_vaccination_country
        FOREIGN KEY (country_id)
        REFERENCES Country_directory(country_id)
);
GO

---POPULATE
INSERT INTO testing_vaccination_metrics(
    country_id,
    date,
    total_tests,
    new_tests,
    total_tests_per_thousand,
    new_tests_per_thousand,
    new_tests_smoothed,
    new_tests_smoothed_per_thousand,
    positive_rate,
    tests_per_case,
    total_vaccinations,
    people_vaccinated,
    people_fully_vaccinated,
    total_boosters,
    new_vaccinations,
    new_vaccinations_smoothed,
    total_vaccinations_per_hundred,
    people_vaccinated_per_hundred,
    people_fully_vaccinated_per_hundred,
    total_boosters_per_hundred,
    new_vaccinations_smoothed_per_million,
    new_people_vaccinated_smoothed,
    new_people_vaccinated_smoothed_per_hundred
)
SELECT
    c.country_id,
    s.date,
    s.total_tests,
    s.new_tests,
    s.total_tests_per_thousand,
    s.new_tests_per_thousand,
    s.new_tests_smoothed,
    s.new_tests_smoothed_per_thousand,
    s.positive_rate,
    s.tests_per_case,
    s.total_vaccinations,
    s.people_vaccinated,
    s.people_fully_vaccinated,
    s.total_boosters,
    s.new_vaccinations,
    s.new_vaccinations_smoothed,
    s.total_vaccinations_per_hundred,
    s.people_vaccinated_per_hundred,
    s.people_fully_vaccinated_per_hundred,
    s.total_boosters_per_hundred,
    s.new_vaccinations_smoothed_per_million,
    s.new_people_vaccinated_smoothed,
    s.new_people_vaccinated_smoothed_per_hundred
FROM health_data s
INNER JOIN Country_directory c
    ON s.country = c.country
WHERE s.date IS NOT NULL;
GO
--CHECK TABLE
SELECT TOP 20 *
FROM testing_vaccination_metrics
ORDER BY date, country_id;
---CONFIRM RELATIONSHIP
SELECT TOP 20
    c.country,
    c.code,
    c.continent,
    f.date,
    f.total_tests,
    f.positive_rate,
    f.total_vaccinations,
    f.people_fully_vaccinated,
    f.total_boosters
FROM testing_vaccination_metrics f
INNER JOIN Country_directory c
    ON f.country_id = c.country_id
ORDER BY f.date, c.country;

--------------------------------------------------------------------------------------------------------------------
---------------------------------------------------EXPLORATORY ANALYSIS--------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
---ADD TWO COLUMNS MONTH AND YEAR TO THE TABLE
ALTER TABLE health_data
ADD month INT,
    year INT;
---FILL IN THE COLUMNS FROM THE DATE
UPDATE health_data
SET
    month = MONTH(date),
    year = YEAR(date);


---CONFIRMATION THAT THE ALTERATION WORKED
SELECT 
    date,
    month,
    year
FROM health_data;

--1.--TOTAL NUMBER OF COUNTRIES AFFECTED BY COVID
SELECT COUNT(DISTINCT country) AS total_countries
FROM health_data;

--2.--LIST OF THE COUNTRIES AFFECTED
SELECT DISTINCT country
FROM health_data
ORDER BY country;

--3.--WHAT PERIOD DOES THE DATA COVER
SELECT
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM health_data;


-4.--POSITIVITY RATE PER COUNTRY
SELECT
    c.country,
    c.code,
    c.continent,
    MAX(h.positive_rate) AS positivity_rate
FROM health_data AS h
INNER JOIN Country_directory AS c
    ON h.code = c.code
WHERE c.continent IS NOT NULL
GROUP BY
    c.country,
    c.code,
    c.continent
ORDER BY positivity_rate DESC;

--5.--OVERALL TOTAL CASES AND DEATHS WITH AGGREGATE COUNTRIES
SELECT
    SUM(CAST(total_cases AS BIGINT)) AS total_cases,
    SUM(CAST(total_deaths AS BIGINT)) AS total_deaths
FROM (
    SELECT
        code,
        MAX(total_cases) AS total_cases,
        MAX(total_deaths) AS total_deaths
    FROM health_data
    WHERE code IS NOT NULL
    GROUP BY code
) AS CountryTotals;


--6.--TOTAL NUMBER OF CASES PER COUNTRY
SELECT
    country,
    MAX(total_cases) AS total_cases
FROM health_data
WHERE continent IS NOT NULL
  AND country NOT IN (
      'Asia excl. China',
      'World',
      'World excl. China'
  )
GROUP BY country
ORDER BY total_cases DESC;


--7.-DISEASE BURDEN PER CONTINENT
SELECT
    continent,
    SUM(new_cases) AS total_cases
FROM health_data
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_cases DESC;


---8.-AVERAGE NEW CASES PER DAY IN EACH COUNTRY
SELECT
    country,
    AVG(new_cases) AS average_daily_cases
FROM health_data
GROUP BY country
ORDER BY average_daily_cases DESC;
---WITHOUT AGGREGATE COUNTRIES
SELECT
    country,
    AVG(new_cases) AS average_daily_cases
FROM health_data
WHERE continent IS NOT NULL
  AND country NOT IN (
      'Asia excl. China',
      'World',
      'World excl. China'
  )
GROUP BY country
ORDER BY average_daily_cases DESC;


--9.--TOP 10 COUNTRIES WITH THE HIGHEST DEATHS
----AGGREGATE COUNTRIES
SELECT
    country,
    total_deaths
FROM (
    SELECT
        country,
        MAX(total_deaths) AS total_deaths,
        ROW_NUMBER() OVER (ORDER BY MAX(total_deaths) DESC) AS rank
    FROM health_data
    GROUP BY country
) AS ranked
WHERE rank <= 10
ORDER BY rank;
----WITHOUT AGGREGATE COUNTRIES
WITH country_deaths AS (
    SELECT
        country,
        MAX(total_deaths) AS total_deaths
    FROM health_data
    WHERE continent IS NOT NULL
      AND code NOT LIKE 'OWID%'
    GROUP BY country
)
SELECT TOP 10
    country,
    total_deaths
FROM country_deaths
ORDER BY total_deaths DESC;

--10.-TOTAL NUMBER OF VACCINATIONS PER COUNTRY
---AGGREGATE COUNTRIES
SELECT
    country,
    MAX(total_vaccinations) AS total_vaccinations
FROM health_data
GROUP BY country
ORDER BY total_vaccinations DESC;
---TOTAL NO OF VACCINATIONS WITHOUT AGGREGATE COUNTRIES
SELECT
    country,
    MAX(total_vaccinations) AS total_vaccinations
FROM health_data
WHERE continent IS NOT NULL
  AND code NOT LIKE 'OWID%'
GROUP BY country
ORDER BY total_vaccinations DESC;

--11. -TOTAL NUMBER OF VACCINATIONS PER YEAR,MONTH IN EVERY COUNTRY
SELECT
    country,
    YEAR(date) AS year,
    DATENAME(MONTH, date) AS month,
    MONTH(date) AS month_number,
    MAX(total_vaccinations) AS total_vaccinations
FROM health_data
WHERE country IS NOT NULL
  AND continent IS NOT NULL
  AND total_vaccinations IS NOT NULL
GROUP BY
    country,
    YEAR(date),
    DATENAME(MONTH, date),
    MONTH(date)
ORDER BY
    country,
    year,
    month_number;

--12.---VACCINATION COVERAGE--------------

WITH LatestVaccination AS (
    SELECT
        c.country,
        c.code,
        c.continent,
        h.date,
        h.people_vaccinated_per_hundred,
        h.people_fully_vaccinated_per_hundred,
        h.total_boosters,

        ROW_NUMBER() OVER (
            PARTITION BY c.country
            ORDER BY h.date DESC
        ) AS rn

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    WHERE c.continent IS NOT NULL
)

SELECT
    country,
    code,
    continent,
    date AS latest_vaccination_date,

    people_vaccinated_per_hundred
        AS vaccinated_coverage,

    people_fully_vaccinated_per_hundred
        AS fully_vaccinated_coverage,

    total_boosters,

    CASE
        WHEN people_fully_vaccinated_per_hundred >= 80
            THEN 'High Coverage'

        WHEN people_fully_vaccinated_per_hundred >= 60
            THEN 'Moderate Coverage'

        WHEN people_fully_vaccinated_per_hundred >= 40
            THEN 'Low Coverage'

        ELSE 'Very Low Coverage'
    END AS vaccination_coverage_level

FROM LatestVaccination

WHERE rn = 1;
GO

--13.--------VACCINATION RISK--------------
SELECT
    c.country,
    c.continent,
    MAX(h.people_fully_vaccinated_per_hundred) AS vaccination_coverage,
    CASE
        WHEN MAX(h.people_fully_vaccinated_per_hundred) < 40
            THEN 'High Risk'
        WHEN MAX(h.people_fully_vaccinated_per_hundred) < 70
            THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS vaccination_risk
FROM health_data AS h
INNER JOIN Country_directory AS c
    ON h.code = c.code
WHERE c.continent IS NOT NULL
GROUP BY
    c.country,
    c.continent
ORDER BY vaccination_coverage DESC;

--14. -COVID NEW_CASES per MONTH

SELECT
    country,
    YEAR(date) AS year,
    MONTH(date) AS month,
    SUM(new_cases) AS total_new_cases
FROM health_data
GROUP BY
    country,
    YEAR(date),
    MONTH(date);


--15. -AVERAGE TOTAL NUMBER OF CASES PER MONTH
SELECT
    AVG(monthly_cases) AS average_monthly_cases
FROM (
    SELECT
        year,
        month,
        SUM(new_cases) AS monthly_cases
    FROM health_data
    GROUP BY year, month
) AS monthly_data;


--16. -TOP 10 COUNTRIES IN HOSPITAL OCCUPANCY
SELECT
    country,
    highest_hospital_patients
FROM (
    SELECT
        country,
        MAX(hosp_patients) AS highest_hospital_patients,
        ROW_NUMBER() OVER (
            ORDER BY MAX(hosp_patients) DESC
        ) AS ranking
    FROM health_data
    GROUP BY country
) AS ranked
WHERE ranking <= 10
ORDER BY ranking;

--17.-TOP 10 COUNTRIES WITH THE HIGHEST BED AVAILABILITY
SELECT
    country,
    beds_per_1000
FROM (
    SELECT
        country,
        MAX(hospital_beds_per_thousand) AS beds_per_1000,
        ROW_NUMBER() OVER (
            ORDER BY MAX(hospital_beds_per_thousand) DESC
        ) AS ranking
    FROM health_data
    WHERE hospital_beds_per_thousand IS NOT NULL
    GROUP BY country
) AS ranked_beds
WHERE ranking <= 10
ORDER BY ranking;


--18. -TOP 10 COUNTRIES WITH LOWEST BED AVAILABILITY
---COUNTRY 10 IS AGGREGATE COUNTRY AND WE DONT WANT
SELECT
    country,
    beds_per_1000
FROM (
    SELECT
        country,
        MAX(hospital_beds_per_thousand) AS beds_per_1000,
        ROW_NUMBER() OVER (
            ORDER BY MAX(hospital_beds_per_thousand) ASC
        ) AS ranking
    FROM health_data
    WHERE hospital_beds_per_thousand IS NOT NULL
    GROUP BY country
) AS ranked_beds
WHERE ranking <= 10
ORDER BY ranking;

----WITHOUT THE AGGREGATE COUNTRY
WITH ranked_beds AS (
    SELECT
        country,
        MAX(hospital_beds_per_thousand) AS beds_per_1000
    FROM health_data
    WHERE hospital_beds_per_thousand IS NOT NULL
      AND continent IS NOT NULL
      AND code NOT LIKE 'OWID%'
    GROUP BY country
)
SELECT TOP 10
    country,
    beds_per_1000
FROM ranked_beds
ORDER BY beds_per_1000 ASC;


--19.-ICU BURDEN PER COUNTRY
SELECT
    country,
    average_icu_burden,
    ranking
FROM (
    SELECT
        country,
        AVG(icu_patients) AS average_icu_burden,
        ROW_NUMBER() OVER (
            ORDER BY AVG(icu_patients) DESC
        ) AS ranking
    FROM health_data
    WHERE icu_patients IS NOT NULL
    GROUP BY country
) AS ranked
WHERE ranking <= 10
ORDER BY ranking;

--20.-DISEASE BURDEN PER CONTINENT
SELECT
    continent,
    SUM(new_cases) AS total_cases
FROM health_data
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_cases DESC;

--21.-DEATH RATE PER COUNTRY
WITH country_totals AS (
    SELECT
        country,
        MAX(total_cases) AS total_cases,
        MAX(total_deaths) AS total_deaths
    FROM health_data
    GROUP BY country
)
SELECT
    country,
    total_cases,
    total_deaths,
    (total_deaths * 100.0 / NULLIF(total_cases, 0)) AS death_rate_percent
FROM country_totals
ORDER BY death_rate_percent DESC;

--22.--HOW HEALTHCARE CAPACITY COMPARES WITH POPULATION PER COUNTRY

SELECT
    country,
    MAX(population) AS population,
    MAX(hospital_beds_per_thousand) AS beds_per_1000,
    MAX(population) * MAX(hospital_beds_per_thousand) / 1000.0
        AS estimated_hospital_beds
FROM health_data
WHERE population IS NOT NULL
  AND hospital_beds_per_thousand IS NOT NULL
GROUP BY country
ORDER BY estimated_hospital_beds DESC;

--23.-TO DETERMINE HEALTHCARE STRAIN PER CONTINENT
SELECT
    continent,
    AVG(hosp_patients) AS avg_hospital_patients,
    AVG(icu_patients) AS avg_icu_patients,
    AVG(weekly_hosp_admissions) AS avg_weekly_hospital_admissions,
    AVG(hospital_beds_per_thousand) AS avg_beds_per_1000
FROM health_data
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY avg_hospital_patients DESC;

--24.-STRAIN PERCENTAGE PER CONTINENT
SELECT
    continent,
    ROUND(AVG(healthcare_strain_score), 2) AS avg_healthcare_strain
FROM vw_HealthcareStrain
WHERE continent IS NOT NULL
  AND healthcare_strain_score IS NOT NULL
GROUP BY continent
ORDER BY avg_healthcare_strain DESC;


--25.-HEALTHCARE STRAIN PER COUNTRY

WITH CountryHealth AS (
    SELECT
        c.country,
        c.code,
        c.continent,

        MAX(h.hosp_patients_per_million) AS hospital_pressure,
        MAX(h.icu_patients_per_million) AS icu_pressure,
        MAX(h.weekly_hosp_admissions_per_million) AS hospital_admission_pressure

    FROM health_data AS h
    INNER JOIN Country_directory AS c
        ON h.code = c.code

    WHERE c.continent IS NOT NULL

    GROUP BY
        c.country,
        c.code,
        c.continent
),

NormalizedHealth AS (
    SELECT
        *,
        
        hospital_pressure /
        NULLIF(MAX(hospital_pressure) OVER (), 0) AS hospital_score,

        icu_pressure /
        NULLIF(MAX(icu_pressure) OVER (), 0) AS icu_score,

        hospital_admission_pressure /
        NULLIF(MAX(hospital_admission_pressure) OVER (), 0) AS admission_score

    FROM CountryHealth
)

SELECT
    country,
    code,
    continent,
    hospital_pressure,
    icu_pressure,
    hospital_admission_pressure,

    ROUND(
        (
            hospital_score * 40
            + icu_score * 40
            + admission_score * 20
        ), 2
    ) AS healthcare_strain_score,

    CASE
        WHEN (
            hospital_score * 40
            + icu_score * 40
            + admission_score * 20
        ) >= 80 THEN 'Critical'

        WHEN (
            hospital_score * 40
            + icu_score * 40
            + admission_score * 20
        ) >= 60 THEN 'Very High'

        WHEN (
            hospital_score * 40
            + icu_score * 40
            + admission_score * 20
        ) >= 40 THEN 'High'

        WHEN (
            hospital_score * 40
            + icu_score * 40
            + admission_score * 20
        ) >= 20 THEN 'Moderate'

        ELSE 'Low'
    END AS healthcare_strain_level

FROM NormalizedHealth
ORDER BY healthcare_strain_score DESC;


--26.-COUNTRIES WITH THE LOWEST ACCESS TO HANDWASHING FACILITIES
SELECT
    country,
    handwashing_facilities,
    ranking
FROM (
    SELECT
        country,
        MAX(handwashing_facilities) AS handwashing_facilities,
        ROW_NUMBER() OVER (
            ORDER BY MAX(handwashing_facilities) ASC
        ) AS ranking
    FROM health_data
    WHERE handwashing_facilities IS NOT NULL
    GROUP BY country
) AS ranked_handwashing
WHERE ranking <= 10
ORDER BY ranking;


--27. -HOW MEDIAN AGE RELATES TO COVID 19 DEATH RATES
SELECT
    country,
    MAX(median_age) AS median_age,
    MAX(total_cases) AS total_cases,
    MAX(total_deaths) AS total_deaths,
    MAX(total_deaths) * 100.0 /
        NULLIF(MAX(total_cases), 0) AS death_rate_percent
FROM health_data
WHERE median_age IS NOT NULL
  AND total_cases IS NOT NULL
  AND total_deaths IS NOT NULL
GROUP BY country
ORDER BY death_rate_percent DESC;

----28.---HEALTHCARE REsiLIENCE RISK ANALYSIS-----------

WITH HealthcareRisk AS (
    SELECT
        c.country,
        c.code,
        c.continent,

        -- Healthcare capacity
        MAX(p.hospital_beds_per_thousand) AS hospital_beds_per_thousand,

        -- Population health risk
        MAX(p.diabetes_prevalence) AS diabetes_prevalence,

        -- Disease burden
        MAX(h.total_cases_per_million) AS cases_per_million,
        MAX(h.total_deaths_per_million) AS deaths_per_million,

        -- Healthcare pressure
        MAX(h.hosp_patients_per_million) AS hospital_pressure,
        MAX(h.icu_patients_per_million) AS icu_pressure,
        MAX(h.weekly_hosp_admissions_per_million) AS hospital_admission_pressure

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    LEFT JOIN Country_Profile AS p
        ON c.country_id = p.country_id

    WHERE c.continent IS NOT NULL

    GROUP BY
        c.country,
        c.code,
        c.continent
),

RiskScores AS (
    SELECT
        *,

        -- Healthcare strain score: 0–100
        (
            hospital_pressure /
            NULLIF(MAX(hospital_pressure) OVER (), 0) * 40

            +

            icu_pressure /
            NULLIF(MAX(icu_pressure) OVER (), 0) * 40

            +

            hospital_admission_pressure /
            NULLIF(MAX(hospital_admission_pressure) OVER (), 0) * 20
        ) AS healthcare_strain_score,

        -- Disease burden score: 0–100
        (
            cases_per_million /
            NULLIF(MAX(cases_per_million) OVER (), 0) * 70

            +

            deaths_per_million /
            NULLIF(MAX(deaths_per_million) OVER (), 0) * 30
        ) AS disease_burden_score

    FROM HealthcareRisk
),

FinalRisk AS (
    SELECT
        *,
        
        -- Overall Healthcare Resilience Risk
        (
            healthcare_strain_score * 0.50
            +
            disease_burden_score * 0.30
            +
            (
                100 -
                (
                    hospital_beds_per_thousand /
                    NULLIF(MAX(hospital_beds_per_thousand) OVER (), 0) * 100
                )
            ) * 0.20
        ) AS resilience_risk_score

    FROM RiskScores
)

SELECT
    country,
    code,
    continent,

    ROUND(healthcare_strain_score, 2)
        AS healthcare_strain_score,

    ROUND(disease_burden_score, 2)
        AS disease_burden_score,

    hospital_beds_per_thousand,

    diabetes_prevalence,

    ROUND(resilience_risk_score, 2)
        AS resilience_risk_score,

    CASE
        WHEN resilience_risk_score >= 75
            THEN 'Critical Risk'

        WHEN resilience_risk_score >= 60
            THEN 'High Risk'

        WHEN resilience_risk_score >= 40
            THEN 'Moderate Risk'

        WHEN resilience_risk_score >= 20
            THEN 'Low Risk'

        ELSE 'Very Low Risk'
    END AS resilience_risk_level

FROM FinalRisk

ORDER BY resilience_risk_score DESC;


SELECT TOP 20
    country,
    code,
    continent,
    healthcare_resilience_risk,
    healthcare_resilience_risk_level
FROM vw_GlobalResilienceAnalysis
WHERE healthcare_resilience_risk IS NOT NULL
ORDER BY healthcare_resilience_risk DESC;

--29.-COUNTRIES THAT APPEAR TO BE PREPARED TO WITHSTAND PRESSURE(HEALTHCARE RESILIENCE)
WITH HealthcareResilience AS (
    SELECT
        c.country,
        c.code,
        c.continent,

        -- Healthcare capacity
        MAX(p.hospital_beds_per_thousand) AS hospital_beds_per_thousand,

        -- Disease burden
        MAX(h.total_cases_per_million) AS cases_per_million,
        MAX(h.total_deaths_per_million) AS deaths_per_million,

        -- Healthcare pressure
        MAX(h.hosp_patients_per_million) AS hospital_pressure,
        MAX(h.icu_patients_per_million) AS icu_pressure,
        MAX(h.weekly_hosp_admissions_per_million) AS hospital_admission_pressure

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    LEFT JOIN Country_Profile AS p
        ON c.country_id = p.country_id

    WHERE c.continent IS NOT NULL

    GROUP BY
        c.country,
        c.code,
        c.continent
),

Normalized AS (
    SELECT
        *,

        -- Healthcare strain
        (
            hospital_pressure /
            NULLIF(MAX(hospital_pressure) OVER (), 0) * 40
            +
            icu_pressure /
            NULLIF(MAX(icu_pressure) OVER (), 0) * 40
            +
            hospital_admission_pressure /
            NULLIF(MAX(hospital_admission_pressure) OVER (), 0) * 20
        ) AS healthcare_strain_score,

        -- Disease burden
        (
            cases_per_million /
            NULLIF(MAX(cases_per_million) OVER (), 0) * 70
            +
            deaths_per_million /
            NULLIF(MAX(deaths_per_million) OVER (), 0) * 30
        ) AS disease_burden_score,

        -- Hospital capacity
        hospital_beds_per_thousand /
        NULLIF(MAX(hospital_beds_per_thousand) OVER (), 0) * 100
        AS hospital_capacity_score

    FROM HealthcareResilience
),

FinalResilience AS (
    SELECT
        *,
        
        (
            hospital_capacity_score * 0.40
            +
            (100 - healthcare_strain_score) * 0.30
            +
            (100 - disease_burden_score) * 0.30
        ) AS resilience_score

    FROM Normalized
)

SELECT
    country,
    code,
    continent,

    ROUND(hospital_capacity_score, 2)
        AS hospital_capacity_score,

    ROUND(100 - healthcare_strain_score, 2)
        AS healthcare_pressure_resilience,

    ROUND(100 - disease_burden_score, 2)
        AS disease_burden_resilience,

    ROUND(resilience_score, 2)
        AS healthcare_resilience_score,

    CASE
        WHEN resilience_score >= 75
            THEN 'Very High Resilience'

        WHEN resilience_score >= 60
            THEN 'High Resilience'

        WHEN resilience_score >= 40
            THEN 'Moderate Resilience'

        WHEN resilience_score >= 20
            THEN 'Low Resilience'

        ELSE 'Very Low Resilience'
    END AS resilience_level

FROM FinalResilience

ORDER BY healthcare_resilience_score DESC;

----30.-HEALTHCARE RESILIENCE BY CONTINENT-------
WITH HealthcareAnalysis AS (
    SELECT
        c.country,
        c.continent,

        MAX(p.hospital_beds_per_thousand) AS hospital_beds_per_thousand,

        MAX(h.total_cases_per_million) AS cases_per_million,
        MAX(h.total_deaths_per_million) AS deaths_per_million,

        MAX(h.hosp_patients_per_million) AS hospital_pressure,
        MAX(h.icu_patients_per_million) AS icu_pressure,
        MAX(h.weekly_hosp_admissions_per_million) AS hospital_admission_pressure

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    LEFT JOIN Country_Profile AS p
        ON c.country_id = p.country_id

    WHERE c.continent IS NOT NULL

    GROUP BY
        c.country,
        c.continent
),

Normalized AS (
    SELECT
        *,

        -- Hospital pressure score
        CASE
            WHEN hospital_pressure IS NOT NULL
            THEN hospital_pressure /
                 NULLIF(MAX(hospital_pressure) OVER (), 0) * 100
        END AS hospital_score,

        -- ICU pressure score
        CASE
            WHEN icu_pressure IS NOT NULL
            THEN icu_pressure /
                 NULLIF(MAX(icu_pressure) OVER (), 0) * 100
        END AS icu_score,

        -- Hospital admissions score
        CASE
            WHEN hospital_admission_pressure IS NOT NULL
            THEN hospital_admission_pressure /
                 NULLIF(MAX(hospital_admission_pressure) OVER (), 0) * 100
        END AS admission_score,

        -- Disease scores
        CASE
            WHEN cases_per_million IS NOT NULL
            THEN cases_per_million /
                 NULLIF(MAX(cases_per_million) OVER (), 0) * 100
        END AS cases_score,

        CASE
            WHEN deaths_per_million IS NOT NULL
            THEN deaths_per_million /
                 NULLIF(MAX(deaths_per_million) OVER (), 0) * 100
        END AS deaths_score,

        -- Hospital capacity
        CASE
            WHEN hospital_beds_per_thousand IS NOT NULL
            THEN hospital_beds_per_thousand /
                 NULLIF(MAX(hospital_beds_per_thousand) OVER (), 0) * 100
        END AS capacity_score

    FROM HealthcareAnalysis
),

CountryScores AS (
    SELECT
        *,

        -- Healthcare strain
        (
            COALESCE(hospital_score, 0) +
            COALESCE(icu_score, 0) +
            COALESCE(admission_score, 0)
        )
        /
        NULLIF(
            (CASE WHEN hospital_score IS NOT NULL THEN 1 ELSE 0 END)
            +
            (CASE WHEN icu_score IS NOT NULL THEN 1 ELSE 0 END)
            +
            (CASE WHEN admission_score IS NOT NULL THEN 1 ELSE 0 END),
            0
        ) AS healthcare_strain_score,

        -- Disease burden
        (
            COALESCE(cases_score, 0) * 0.70
            +
            COALESCE(deaths_score, 0) * 0.30
        )
        /
        NULLIF(
            (CASE WHEN cases_score IS NOT NULL THEN 0.70 ELSE 0 END)
            +
            (CASE WHEN deaths_score IS NOT NULL THEN 0.30 ELSE 0 END),
            0
        ) AS disease_burden_score

    FROM Normalized
),

FinalScores AS (
    SELECT
        *,

        -- Resilience
        (
            COALESCE(capacity_score, 0) * 0.40
            +
            (100 - COALESCE(healthcare_strain_score, 0)) * 0.30
            +
            (100 - COALESCE(disease_burden_score, 0)) * 0.30
        ) AS resilience_score,

        -- Risk
        (
            COALESCE(healthcare_strain_score, 0) * 0.50
            +
            COALESCE(disease_burden_score, 0) * 0.30
            +
            (100 - COALESCE(capacity_score, 0)) * 0.20
        ) AS risk_score

    FROM CountryScores
)

SELECT
    continent,

    COUNT(*) AS number_of_countries,

    ROUND(AVG(resilience_score), 2)
        AS average_resilience_score,

    ROUND(AVG(risk_score), 2)
        AS average_risk_score,

    ROUND(AVG(healthcare_strain_score), 2)
        AS average_healthcare_strain,

    ROUND(AVG(hospital_beds_per_thousand), 2)
        AS average_hospital_beds_per_thousand,

    ROUND(AVG(cases_per_million), 2)
        AS average_cases_per_million,

    ROUND(AVG(deaths_per_million), 2)
        AS average_deaths_per_million

FROM FinalScores

GROUP BY continent

ORDER BY average_resilience_score DESC;



/*--------------------------------------------------------------
 31. Data availability by region
--------------------------------------------------------------*/

SELECT
    continent,

    COUNT(*) AS ObservationCount,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN hosp_patients_per_million IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS HospitalCompletenessPct,


    CAST(
        100.0 *
        SUM(
            CASE
                WHEN icu_patients_per_million IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS ICUCompletenessPct,


    CAST(
        100.0 *
        SUM(
            CASE
                WHEN positive_rate IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS TestingCompletenessPct,


    CAST(
        100.0 *
        SUM(
            CASE
                WHEN people_fully_vaccinated_per_hundred
                     IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS VaccinationCompletenessPct

FROM health_data

WHERE country IS NOT NULL
  AND continent IS NOT NULL

GROUP BY continent

ORDER BY ICUCompletenessPct;

/*--------------------------------------------------------------
31. Data Completeness by country
--------------------------------------------------------------*/

SELECT
    country,
    continent,

    COUNT(*) AS TotalObservations,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN total_cases IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS CasesCompletenessPct,


    CAST(
        100.0 *
        SUM(
            CASE
                WHEN hosp_patients_per_million IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS HospitalCompletenessPct,


    CAST(
        100.0 *
        SUM(
            CASE
                WHEN icu_patients_per_million IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS ICUCompletenessPct,


    CAST(
        100.0 *
        SUM(
            CASE
                WHEN positive_rate IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS TestingCompletenessPct,


    CAST(
        100.0 *
        SUM(
            CASE
                WHEN people_fully_vaccinated_per_hundred
                     IS NOT NULL
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)

        AS DECIMAL(6,2)
    ) AS VaccinationCompletenessPct

FROM health_data

WHERE continent IS NOT NULL

GROUP BY
    country,
    continent

ORDER BY
    ICUCompletenessPct,
    HospitalCompletenessPct;


---------------------------------------------------------------------------------------------------------
--------------------------------------------CREATING VIEWS-------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
----CountryHealthProfile view
CREATE VIEW vw_CountryHealthProfile AS
SELECT
    c.country_id,
    c.country,
    c.code,
    c.continent,

    p.population,
    p.population_density,
    p.median_age,
    p.life_expectancy,
    p.gdp_per_capita,
    p.extreme_poverty,
    p.diabetes_prevalence,
    p.handwashing_facilities,
    p.hospital_beds_per_thousand,
    p.human_development_index

FROM Country_directory AS c

LEFT JOIN Country_Profile AS p
    ON c.country_id = p.country_id

WHERE c.continent IS NOT NULL;
GO

SELECT *
FROM vw_CountryHealthProfile
ORDER BY country;


----Disease Burden View
CREATE VIEW vw_DiseaseBurden AS
WITH LatestDiseaseData AS (
    SELECT
        c.country,
        c.code,
        c.continent,
        h.date,
        h.total_cases,
        h.total_deaths,
        h.total_cases_per_million,
        h.total_deaths_per_million,
        h.reproduction_rate,

        ROW_NUMBER() OVER (
            PARTITION BY c.country
            ORDER BY h.date DESC
        ) AS rn

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    WHERE c.continent IS NOT NULL
)

SELECT
    country,
    code,
    continent,
    date AS latest_disease_date,
    total_cases,
    total_deaths,
    total_cases_per_million,
    total_deaths_per_million,
    reproduction_rate,

    CASE
        WHEN reproduction_rate >= 1.5 THEN 'Very High'
        WHEN reproduction_rate >= 1.0 THEN 'High'
        WHEN reproduction_rate >= 0.8 THEN 'Moderate'
        ELSE 'Low'
    END AS transmission_risk

FROM LatestDiseaseData
WHERE rn = 1;
GO

SELECT *
FROM vw_DiseaseBurden
ORDER BY total_cases_per_million DESC;

---Vaccination Coverage View
CREATE VIEW vw_VaccinationCoverage AS
WITH LatestVaccination AS (
    SELECT
        c.country,
        c.code,
        c.continent,
        h.date,
        h.people_vaccinated_per_hundred,
        h.people_fully_vaccinated_per_hundred,
        h.total_boosters,

        ROW_NUMBER() OVER (
            PARTITION BY c.country
            ORDER BY h.date DESC
        ) AS rn

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    WHERE c.continent IS NOT NULL
)

SELECT
    country,
    code,
    continent,

    date AS latest_vaccination_date,

    people_vaccinated_per_hundred
        AS vaccinated_coverage,

    people_fully_vaccinated_per_hundred
        AS fully_vaccinated_coverage,

    total_boosters,

    CASE
        WHEN people_fully_vaccinated_per_hundred >= 80
            THEN 'High Coverage'

        WHEN people_fully_vaccinated_per_hundred >= 60
            THEN 'Moderate Coverage'

        WHEN people_fully_vaccinated_per_hundred >= 40
            THEN 'Low Coverage'

        ELSE 'Very Low Coverage'
    END AS vaccination_coverage_level

FROM LatestVaccination
WHERE rn = 1;
GO

SELECT *
FROM vw_VaccinationCoverage
ORDER BY fully_vaccinated_coverage DESC;


---Healthcare Strain view
CREATE VIEW vw_HealthcareStrain AS
WITH CountryHealth AS (
    SELECT
        c.country,
        c.code,
        c.continent,

        MAX(h.hosp_patients_per_million) AS hospital_pressure,
        MAX(h.icu_patients_per_million) AS icu_pressure,
        MAX(h.weekly_hosp_admissions_per_million) AS hospital_admission_pressure

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    WHERE c.continent IS NOT NULL

    GROUP BY
        c.country,
        c.code,
        c.continent
),

NormalizedHealth AS (
    SELECT
        *,
        
        hospital_pressure /
        NULLIF(MAX(hospital_pressure) OVER (), 0)
        AS hospital_score,

        icu_pressure /
        NULLIF(MAX(icu_pressure) OVER (), 0)
        AS icu_score,

        hospital_admission_pressure /
        NULLIF(MAX(hospital_admission_pressure) OVER (), 0)
        AS admission_score

    FROM CountryHealth
)

SELECT
    country,
    code,
    continent,

    hospital_pressure,
    icu_pressure,
    hospital_admission_pressure,

    ROUND(
        hospital_score * 40
        +
        icu_score * 40
        +
        admission_score * 20,
        2
    ) AS healthcare_strain_score,

    CASE
        WHEN hospital_score * 40
           + icu_score * 40
           + admission_score * 20 >= 80
            THEN 'Critical'

        WHEN hospital_score * 40
           + icu_score * 40
           + admission_score * 20 >= 60
            THEN 'Very High'

        WHEN hospital_score * 40
           + icu_score * 40
           + admission_score * 20 >= 40
            THEN 'High'

        WHEN hospital_score * 40
           + icu_score * 40
           + admission_score * 20 >= 20
            THEN 'Moderate'

        ELSE 'Low'
    END AS healthcare_strain_level

FROM NormalizedHealth;
GO

SELECT *
FROM vw_HealthcareStrain
ORDER BY healthcare_strain_score DESC;

---GlobalResilience Analysis view
CREATE VIEW vw_GlobalResilienceAnalysis AS

WITH BaseData AS (
    SELECT
        p.country_id,
        p.country,
        p.code,
        p.continent,

        -- Country profile
        p.population,
        p.population_density,
        p.median_age,
        p.life_expectancy,
        p.gdp_per_capita,
        p.extreme_poverty,
        p.diabetes_prevalence,
        p.hospital_beds_per_thousand,
        p.human_development_index,

        -- Disease burden
        d.latest_disease_date,
        d.total_cases,
        d.total_deaths,
        d.total_cases_per_million,
        d.total_deaths_per_million,
        d.reproduction_rate,
        d.transmission_risk,

        -- Vaccination
        v.latest_vaccination_date,
        v.vaccinated_coverage,
        v.fully_vaccinated_coverage,
        v.total_boosters,
        v.vaccination_coverage_level,

        -- Healthcare strain
        s.hospital_pressure,
        s.icu_pressure,
        s.hospital_admission_pressure,
        s.healthcare_strain_score,
        s.healthcare_strain_level

    FROM vw_CountryHealthProfile AS p

    LEFT JOIN vw_DiseaseBurden AS d
        ON p.country = d.country

    LEFT JOIN vw_VaccinationCoverage AS v
        ON p.country = v.country

    LEFT JOIN vw_HealthcareStrain AS s
        ON p.country = s.country
),

NormalizedData AS (
    SELECT
        *,

        -- Disease burden score: 0–100
        (
            total_cases_per_million /
            NULLIF(
                MAX(total_cases_per_million) OVER (),
                0
            ) * 70

            +

            total_deaths_per_million /
            NULLIF(
                MAX(total_deaths_per_million) OVER (),
                0
            ) * 30
        ) AS disease_burden_score,

        -- Hospital capacity score: 0–100
        hospital_beds_per_thousand /
        NULLIF(
            MAX(hospital_beds_per_thousand) OVER (),
            0
        ) * 100 AS hospital_capacity_score

    FROM BaseData
),

FinalScores AS (
    SELECT
        *,

        -- Healthcare Resilience Score
        (
            hospital_capacity_score * 0.40
            +
            (100 - healthcare_strain_score) * 0.30
            +
            (100 - disease_burden_score) * 0.30
        ) AS healthcare_resilience_score,

        -- Healthcare Resilience Risk Score
        (
            healthcare_strain_score * 0.50
            +
            disease_burden_score * 0.30
            +
            (100 - hospital_capacity_score) * 0.20
        ) AS healthcare_resilience_risk_score

    FROM NormalizedData
)

SELECT
    country_id,
    country,
    code,
    continent,

    population,
    population_density,
    median_age,
    life_expectancy,
    gdp_per_capita,
    extreme_poverty,
    diabetes_prevalence,
    hospital_beds_per_thousand,
    human_development_index,

    latest_disease_date,
    total_cases,
    total_deaths,
    total_cases_per_million,
    total_deaths_per_million,
    reproduction_rate,
    transmission_risk,

    latest_vaccination_date,
    vaccinated_coverage,
    fully_vaccinated_coverage,
    total_boosters,
    vaccination_coverage_level,

    hospital_pressure,
    icu_pressure,
    hospital_admission_pressure,
    healthcare_strain_score,
    healthcare_strain_level,

    ROUND(disease_burden_score, 2)
        AS disease_burden_score,

    ROUND(hospital_capacity_score, 2)
        AS hospital_capacity_score,

    ROUND(healthcare_resilience_score, 2)
        AS healthcare_resilience_score,

    CASE
        WHEN healthcare_resilience_score >= 75
            THEN 'Very High Resilience'

        WHEN healthcare_resilience_score >= 60
            THEN 'High Resilience'

        WHEN healthcare_resilience_score >= 40
            THEN 'Moderate Resilience'

        WHEN healthcare_resilience_score >= 20
            THEN 'Low Resilience'

        ELSE 'Very Low Resilience'
    END AS resilience_level,

    ROUND(healthcare_resilience_risk_score, 2)
        AS healthcare_resilience_risk_score,

    CASE
        WHEN healthcare_resilience_risk_score >= 75
            THEN 'Critical Risk'

        WHEN healthcare_resilience_risk_score >= 60
            THEN 'High Risk'

        WHEN healthcare_resilience_risk_score >= 40
            THEN 'Moderate Risk'

        WHEN healthcare_resilience_risk_score >= 20
            THEN 'Low Risk'

        ELSE 'Very Low Risk'
    END AS risk_level

FROM FinalScores;
GO

SELECT *
FROM vw_GlobalResilienceAnalysis
ORDER BY healthcare_resilience_risk_score DESC;


---DATA COMPLETENESS VIEW----
CREATE VIEW vw_DataCompleteness
AS

SELECT

    country,
    code,
    continent,

    COUNT(*) AS TotalObservations,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN total_cases IS NOT NULL
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(6,2)
    ) AS CasesCompletenessPct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN hosp_patients_per_million IS NOT NULL
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(6,2)
    ) AS HospitalCompletenessPct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN icu_patients_per_million IS NOT NULL
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(6,2)
    ) AS ICUCompletenessPct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN positive_rate IS NOT NULL
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(6,2)
    ) AS TestingCompletenessPct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN people_fully_vaccinated_per_hundred
                     IS NOT NULL
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(6,2)
    ) AS VaccinationCompletenessPct

FROM health_data

WHERE continent IS NOT NULL

GROUP BY
    country,
    code,
    continent



-------------------------------------------------------------------------------------------------------------------
-------------------------------------------ALTERATIONS-----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

ALTER VIEW vw_HealthcareStrain 
AS
WITH CountryHealth AS (
    SELECT
        c.country,
        c.code,
        c.continent,

        MAX(h.hosp_patients_per_million) AS hospital_pressure,
        MAX(h.icu_patients_per_million) AS icu_pressure,
        MAX(h.weekly_hosp_admissions_per_million) AS hospital_admission_pressure

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    WHERE c.continent IS NOT NULL

    GROUP BY
        c.country,
        c.code,
        c.continent
),

NormalizedHealth AS (
    SELECT
        *,

        hospital_pressure /
        NULLIF(MAX(hospital_pressure) OVER (), 0) AS hospital_score,

        icu_pressure /
        NULLIF(MAX(icu_pressure) OVER (), 0) AS icu_score,

        hospital_admission_pressure /
        NULLIF(MAX(hospital_admission_pressure) OVER (), 0)
        AS admission_score

    FROM CountryHealth
),

FinalStrain AS (
    SELECT
        *,

        (
            COALESCE(hospital_score * 40, 0)
            +
            COALESCE(icu_score * 40, 0)
            +
            COALESCE(admission_score * 20, 0)
        )
        /
        NULLIF(
            (CASE WHEN hospital_score IS NOT NULL THEN 40 ELSE 0 END)
            +
            (CASE WHEN icu_score IS NOT NULL THEN 40 ELSE 0 END)
            +
            (CASE WHEN admission_score IS NOT NULL THEN 20 ELSE 0 END),
            0
        ) AS healthcare_strain_score

    FROM NormalizedHealth
)

SELECT
    country,
    code,
    continent,

    hospital_pressure,
    icu_pressure,
    hospital_admission_pressure,

    ROUND(healthcare_strain_score * 100, 2)
        AS healthcare_strain_score,

    CASE
        WHEN healthcare_strain_score * 100 >= 80
            THEN 'Critical'

        WHEN healthcare_strain_score * 100 >= 60
            THEN 'Very High'

        WHEN healthcare_strain_score * 100 >= 40
            THEN 'High'

        WHEN healthcare_strain_score * 100 >= 20
            THEN 'Moderate'

        ELSE 'Low'
    END AS healthcare_strain_level

FROM FinalStrain;
GO

SELECT
    COUNT(*) AS total_countries,

    SUM(
        CASE
            WHEN healthcare_strain_score IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_strain

FROM vw_HealthcareStrain;

SELECT
    COUNT(*) AS total_countries,

    SUM(CASE
        WHEN total_cases_per_million IS NOT NULL THEN 1
        ELSE 0
    END) AS countries_with_cases_data,

    SUM(CASE
        WHEN total_deaths_per_million IS NOT NULL THEN 1
        ELSE 0
    END) AS countries_with_deaths_data,

    SUM(CASE
        WHEN total_cases_per_million IS NULL
         AND total_deaths_per_million IS NULL
        THEN 1
        ELSE 0
    END) AS countries_with_no_disease_data

FROM vw_DiseaseBurden;

SELECT * FROM vw_HealthcareStrain
----------------------------------------------------
ALTER VIEW vw_DiseaseBurden AS

WITH DiseaseData AS (
    SELECT
        c.country,
        c.code,
        c.continent,
        h.date,
        h.total_cases,
        h.total_deaths,
        h.total_cases_per_million,
        h.total_deaths_per_million,
        h.reproduction_rate,

        ROW_NUMBER() OVER (
            PARTITION BY c.country
            ORDER BY h.date DESC
        ) AS rn

    FROM health_data AS h

    INNER JOIN Country_directory AS c
        ON h.code = c.code

    WHERE c.continent IS NOT NULL

      -- Only use records containing actual disease data
      AND (
            h.total_cases IS NOT NULL
            OR h.total_deaths IS NOT NULL
            OR h.total_cases_per_million IS NOT NULL
            OR h.total_deaths_per_million IS NOT NULL
          )
)

SELECT
    country,
    code,
    continent,

    date AS latest_disease_date,

    total_cases,
    total_deaths,
    total_cases_per_million,
    total_deaths_per_million,
    reproduction_rate,

    CASE
        WHEN reproduction_rate >= 1.5
            THEN 'Very High'

        WHEN reproduction_rate >= 1.0
            THEN 'High'

        WHEN reproduction_rate >= 0.8
            THEN 'Moderate'

        ELSE 'Low'
    END AS transmission_risk

FROM DiseaseData

WHERE rn = 1;
GO

SELECT TOP 20
    country,
    latest_disease_date,
    total_cases_per_million,
    total_deaths_per_million,
    reproduction_rate,
    transmission_risk
FROM vw_DiseaseBurden
ORDER BY country;

SELECT
    COUNT(*) AS total_countries,

    SUM(
        CASE
            WHEN total_cases_per_million IS NULL
             AND total_deaths_per_million IS NULL
            THEN 1
            ELSE 0
        END
    ) AS countries_with_no_disease_data

FROM vw_DiseaseBurden;

SELECT
    COUNT(*) AS total_countries,

    SUM(
        CASE
            WHEN healthcare_resilience_score IS NOT NULL
             AND healthcare_resilience_risk_score IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS countries_with_complete_scores,

    SUM(
        CASE
            WHEN healthcare_resilience_score IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_resilience_score,

    SUM(
        CASE
            WHEN healthcare_resilience_risk_score IS NULL
            THEN 1
            ELSE 0
        END
    ) AS missing_risk_score

FROM vw_GlobalResilienceAnalysis;


SELECT TOP 20
    country,
    continent,
    healthcare_resilience_score,
    healthcare_resilience_risk_score
FROM vw_GlobalResilienceAnalysis
WHERE healthcare_resilience_score IS NOT NULL
ORDER BY healthcare_resilience_score DESC;

SELECT * FROM vw_DiseaseBurden

SELECT * FROM vw_GlobalResilienceAnalysis
------------------------------------------

---MORE VIEWS----

------------------------------------------
CREATE VIEW vw_LowHandwashingAccess AS
SELECT
    country_id,
    country,
    code,
    continent,
    population,
    handwashing_facilities,
    CASE
        WHEN handwashing_facilities < 20 THEN 'Very Low Access'
        WHEN handwashing_facilities < 40 THEN 'Low Access'
        WHEN handwashing_facilities < 60 THEN 'Moderate Access'
        WHEN handwashing_facilities < 80 THEN 'High Access'
        ELSE 'Very High Access'
    END AS handwashing_access_level
FROM vw_CountryHealthProfile
WHERE handwashing_facilities IS NOT NULL;
GO

SELECT *
FROM vw_LowHandwashingAccess
ORDER BY handwashing_facilities ASC;

----------------------------------

CREATE VIEW vw_MedianAgeDeathRate AS
SELECT
    p.country_id,
    p.country,
    p.code,
    p.continent,
    p.median_age,
    d.total_deaths,
    d.total_deaths_per_million,
    CASE
        WHEN d.total_deaths_per_million >= 1000 THEN 'Very High Death Rate'
        WHEN d.total_deaths_per_million >= 500 THEN 'High Death Rate'
        WHEN d.total_deaths_per_million >= 100 THEN 'Moderate Death Rate'
        ELSE 'Low Death Rate'
    END AS death_rate_level
FROM vw_CountryHealthProfile AS p
INNER JOIN vw_DiseaseBurden AS d
    ON p.code = d.code
WHERE p.median_age IS NOT NULL
  AND d.total_deaths_per_million IS NOT NULL;
GO
-------------------------------------------------
CREATE VIEW vw_HealthcareCapacityPopulation AS
SELECT
    country_id,
    country,
    code,
    continent,
    population,
    hospital_beds_per_thousand,

    ROUND(
        (population / 1000.0) *
        hospital_beds_per_thousand,
        0
    ) AS estimated_hospital_beds,

    hospital_capacity_score,

    CASE
        WHEN hospital_beds_per_thousand >= 8 THEN 'Very High Capacity'
        WHEN hospital_beds_per_thousand >= 5 THEN 'High Capacity'
        WHEN hospital_beds_per_thousand >= 3 THEN 'Moderate Capacity'
        WHEN hospital_beds_per_thousand >= 1 THEN 'Low Capacity'
        ELSE 'Very Low Capacity'
    END AS healthcare_capacity_level

FROM vw_GlobalResilienceAnalysis
WHERE population IS NOT NULL
  AND hospital_beds_per_thousand IS NOT NULL;
GO

----------------------------------------------------------

CREATE VIEW vw_HealthResilienceTrends AS

SELECT
    h.date,
    YEAR(h.date) AS year,
    MONTH(h.date) AS month_number,
    DATENAME(MONTH, h.date) AS month_name,

    c.country_id,
    c.country,
    c.code,
    c.continent,

    -- COVID-19 indicators
    h.new_cases,
    h.total_cases,
    h.new_deaths,
    h.total_deaths,

    h.new_cases_per_million,
    h.new_deaths_per_million,

    -- Testing
    h.new_tests,
    h.total_tests,
    h.positive_rate,

    -- Vaccination
    h.people_vaccinated_per_hundred,
    h.people_fully_vaccinated_per_hundred,
    h.total_boosters,

    -- Healthcare pressure
    h.hosp_patients_per_million,
    h.icu_patients_per_million,
    h.weekly_hosp_admissions_per_million,

    -- Transmission
    h.reproduction_rate

FROM health_data AS h

INNER JOIN Country_directory AS c
    ON h.code = c.code

WHERE c.continent IS NOT NULL;
GO

SELECT TOP 50 *
FROM vw_HealthResilienceTrends
ORDER BY date, country;

---TO CONFIRM WHETHER DATE AND COUNTRIES ARE APPEARING CORRECTLY
SELECT
    year,
    month_number,
    month_name,
    COUNT(*) AS records
FROM vw_HealthResilienceTrends
GROUP BY
    year,
    month_number,
    month_name
ORDER BY
    year,
    month_number;

----CHECK IMPORTANT TREND FIELDS
SELECT
    COUNT(*) AS total_records,

    COUNT(new_cases) AS cases_records,
    COUNT(new_deaths) AS deaths_records,
    COUNT(positive_rate) AS positivity_records,
    COUNT(people_fully_vaccinated_per_hundred) AS vaccination_records,
    COUNT(hosp_patients_per_million) AS hospital_pressure_records,
    COUNT(icu_patients_per_million) AS icu_pressure_records

FROM vw_HealthResilienceTrends;

-------------------------------------------

ALTER VIEW vw_HealthResilienceTrends AS
SELECT
    h.date,
    YEAR(h.date) AS year,
    MONTH(h.date) AS month_number,
    DATENAME(MONTH, h.date) AS month_name,

    c.country_id,
    c.country,
    c.code,
    c.continent,

    h.new_cases,
    h.total_cases,
    h.new_deaths,
    h.total_deaths,
    h.new_cases_per_million,
    h.new_deaths_per_million,

    h.new_tests,
    h.total_tests,
    h.positive_rate,

    h.people_vaccinated_per_hundred,
    h.people_fully_vaccinated_per_hundred,
    h.total_boosters,

    h.hosp_patients_per_million,
    h.icu_patients_per_million,
    h.weekly_hosp_admissions_per_million,

    h.reproduction_rate,
    h.stringency_index

FROM health_data AS h
INNER JOIN Country_directory AS c
    ON h.code = c.code
WHERE c.continent IS NOT NULL;
GO

SELECT TOP 10
    date,
    country,
    continent,
    stringency_index
FROM vw_HealthResilienceTrends
WHERE stringency_index IS NOT NULL
ORDER BY date;
SELECT 
    TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME LIKE '%Resilience%'
   OR TABLE_NAME LIKE '%Stringency%';




USE global_resilience;
GO

BEGIN TRY

    BEGIN TRANSACTION;

    ------------------------------------------------------------
    -- 1. CREATE A MAP:
    --    duplicate country_id → original/kept country_id
    ------------------------------------------------------------

    IF OBJECT_ID('tempdb..#CountryMap') IS NOT NULL
        DROP TABLE #CountryMap;

    SELECT
        duplicate_country_id = d.country_id,
        keep_country_id = k.keep_country_id
    INTO #CountryMap
    FROM Country_directory AS d
    INNER JOIN (
        SELECT
            code,
            MIN(country_id) AS keep_country_id
        FROM Country_directory
        WHERE code IS NOT NULL
        GROUP BY code
        HAVING COUNT(*) > 1
    ) AS k
        ON d.code = k.code
    WHERE d.country_id <> k.keep_country_id;


    ------------------------------------------------------------
    -- 2. MOVE Country_Profile RECORDS
    ------------------------------------------------------------

    UPDATE cp
    SET cp.country_id = m.keep_country_id
    FROM Country_Profile AS cp
    INNER JOIN #CountryMap AS m
        ON cp.country_id = m.duplicate_country_id;


    ------------------------------------------------------------
    -- 3. MOVE health_metrics RECORDS
    ------------------------------------------------------------

    UPDATE hm
    SET hm.country_id = m.keep_country_id
    FROM health_metrics AS hm
    INNER JOIN #CountryMap AS m
        ON hm.country_id = m.duplicate_country_id;


    ------------------------------------------------------------
    -- 4. MOVE healthcare_capacity RECORDS
    ------------------------------------------------------------

    UPDATE hc
    SET hc.country_id = m.keep_country_id
    FROM healthcare_capacity AS hc
    INNER JOIN #CountryMap AS m
        ON hc.country_id = m.duplicate_country_id;


    ------------------------------------------------------------
    -- 5. MOVE testing_vaccination_metrics RECORDS
    ------------------------------------------------------------

    UPDATE tv
    SET tv.country_id = m.keep_country_id
    FROM testing_vaccination_metrics AS tv
    INNER JOIN #CountryMap AS m
        ON tv.country_id = m.duplicate_country_id;


    ------------------------------------------------------------
    -- 6. REMOVE DUPLICATE Country_Profile RECORDS
    --    Keep only ONE profile per country
    ------------------------------------------------------------

    ;WITH DuplicateProfiles AS
    (
        SELECT
            profile_id,
            ROW_NUMBER() OVER (
                PARTITION BY country_id
                ORDER BY profile_id
            ) AS rn
        FROM Country_Profile
    )
    DELETE FROM DuplicateProfiles
    WHERE rn > 1;


    ------------------------------------------------------------
    -- 7. REMOVE DUPLICATE DAILY health_metrics RECORDS
    --    Keep one record per country/date
    ------------------------------------------------------------

    ;WITH DuplicateHealth AS
    (
        SELECT
            metric_id,
            ROW_NUMBER() OVER (
                PARTITION BY country_id, date
                ORDER BY metric_id
            ) AS rn
        FROM health_metrics
    )
    DELETE FROM DuplicateHealth
    WHERE rn > 1;


    ------------------------------------------------------------
    -- 8. REMOVE DUPLICATE DAILY healthcare_capacity RECORDS
    ------------------------------------------------------------

    ;WITH DuplicateCapacity AS
    (
        SELECT
            capacity_id,
            ROW_NUMBER() OVER (
                PARTITION BY country_id, date
                ORDER BY capacity_id
            ) AS rn
        FROM healthcare_capacity
    )
    DELETE FROM DuplicateCapacity
    WHERE rn > 1;


    ------------------------------------------------------------
    -- 9. REMOVE DUPLICATE DAILY testing/vaccination RECORDS
    ------------------------------------------------------------

    ;WITH DuplicateTesting AS
    (
        SELECT
            testing_id,
            ROW_NUMBER() OVER (
                PARTITION BY country_id, date
                ORDER BY testing_id
            ) AS rn
        FROM testing_vaccination_metrics
    )
    DELETE FROM DuplicateTesting
    WHERE rn > 1;


    ------------------------------------------------------------
    -- 10. REMOVE DUPLICATE COUNTRIES FROM Country_directory
    ------------------------------------------------------------

    DELETE cd
    FROM Country_directory AS cd
    INNER JOIN #CountryMap AS m
        ON cd.country_id = m.duplicate_country_id;


    ------------------------------------------------------------
    -- 11. FINISH
    ------------------------------------------------------------

    COMMIT TRANSACTION;

    PRINT 'REPAIR COMPLETED SUCCESSFULLY.';

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'REPAIR FAILED - ALL CHANGES HAVE BEEN ROLLED BACK.';

    THROW;

END CATCH;
GO


