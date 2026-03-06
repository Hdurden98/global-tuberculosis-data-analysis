-- Global Tuberculosis SQL Case Study
-- Author: Hannah Durden
-- This project analyzes tuberculosis cases, deaths, and detection rates
-- across countries and regions using SQL.

-- Assumed table name: tuberculosis_data
-- Assumed columns:
-- country, region, year, tb_cases, tb_deaths, population, detection_rate

--------------------------------------------------
-- 1. Total TB cases and deaths by region
--------------------------------------------------
SELECT
    region,
    SUM(tb_cases) AS total_cases,
    SUM(tb_deaths) AS total_deaths
FROM tuberculosis_data
GROUP BY region
ORDER BY total_cases DESC;

--------------------------------------------------
-- 2. Countries with the highest TB burden
--------------------------------------------------
SELECT
    country,
    SUM(tb_cases) AS total_cases
FROM tuberculosis_data
GROUP BY country
ORDER BY total_cases DESC
LIMIT 10;

--------------------------------------------------
-- 3. Mortality rate by country
--------------------------------------------------
SELECT
    country,
    SUM(tb_deaths) AS total_deaths,
    SUM(tb_cases) AS total_cases,
    ROUND((SUM(tb_deaths) * 100.0 / NULLIF(SUM(tb_cases), 0)), 2) AS mortality_rate_pct
FROM tuberculosis_data
GROUP BY country
ORDER BY mortality_rate_pct DESC;

--------------------------------------------------
-- 4. Average detection rate by region
--------------------------------------------------
SELECT
    region,
    ROUND(AVG(detection_rate), 2) AS avg_detection_rate
FROM tuberculosis_data
GROUP BY region
ORDER BY avg_detection_rate DESC;

--------------------------------------------------
-- 5. Yearly global TB trend
--------------------------------------------------
SELECT
    year,
    SUM(tb_cases) AS global_cases,
    SUM(tb_deaths) AS global_deaths
FROM tuberculosis_data
GROUP BY year
ORDER BY year;

--------------------------------------------------
-- 6. Running total of TB cases over time
--------------------------------------------------
SELECT
    year,
    SUM(tb_cases) AS yearly_cases,
    SUM(SUM(tb_cases)) OVER (ORDER BY year) AS running_total_cases
FROM tuberculosis_data
GROUP BY year
ORDER BY year;

--------------------------------------------------
-- 7. Rank countries by total TB cases
--------------------------------------------------
SELECT
    country,
    SUM(tb_cases) AS total_cases,
    RANK() OVER (ORDER BY SUM(tb_cases) DESC) AS case_rank
FROM tuberculosis_data
GROUP BY country
ORDER BY case_rank;

--------------------------------------------------
-- 8. Top country in each region by TB cases
--------------------------------------------------
WITH regional_country_cases AS (
    SELECT
        region,
        country,
        SUM(tb_cases) AS total_cases,
        RANK() OVER (
            PARTITION BY region
            ORDER BY SUM(tb_cases) DESC
        ) AS regional_rank
    FROM tuberculosis_data
    GROUP BY region, country
)
SELECT
    region,
    country,
    total_cases
FROM regional_country_cases
WHERE regional_rank = 1
ORDER BY total_cases DESC;

--------------------------------------------------
-- 9. Year-over-year change in global TB cases
--------------------------------------------------
WITH yearly_cases AS (
    SELECT
        year,
        SUM(tb_cases) AS total_cases
    FROM tuberculosis_data
    GROUP BY year
)
SELECT
    year,
    total_cases,
    LAG(total_cases) OVER (ORDER BY year) AS previous_year_cases,
    total_cases - LAG(total_cases) OVER (ORDER BY year) AS yoy_change
FROM yearly_cases
ORDER BY year;

--------------------------------------------------
-- 10. Countries with above-average TB cases
--------------------------------------------------
WITH country_totals AS (
    SELECT
        country,
        SUM(tb_cases) AS total_cases
    FROM tuberculosis_data
    GROUP BY country
)
SELECT
    country,
    total_cases
FROM country_totals
WHERE total_cases > (SELECT AVG(total_cases) FROM country_totals)
ORDER BY total_cases DESC;

--------------------------------------------------
-- 11. Case fatality rate by region and year
--------------------------------------------------
SELECT
    region,
    year,
    SUM(tb_deaths) AS total_deaths,
    SUM(tb_cases) AS total_cases,
    ROUND((SUM(tb_deaths) * 100.0 / NULLIF(SUM(tb_cases), 0)), 2) AS case_fatality_rate_pct
FROM tuberculosis_data
GROUP BY region, year
ORDER BY region, year;

--------------------------------------------------
-- 12. Countries with low detection but high mortality
--------------------------------------------------
SELECT
    country,
    ROUND(AVG(detection_rate), 2) AS avg_detection_rate,
    ROUND((SUM(tb_deaths) * 100.0 / NULLIF(SUM(tb_cases), 0)), 2) AS mortality_rate_pct
FROM tuberculosis_data
GROUP BY country
HAVING AVG(detection_rate) < 60
   AND (SUM(tb_deaths) * 100.0 / NULLIF(SUM(tb_cases), 0)) > 5
ORDER BY mortality_rate_pct DESC;

--------------------------------------------------
-- 13. Regional share of global TB cases
--------------------------------------------------
WITH regional_cases AS (
    SELECT
        region,
        SUM(tb_cases) AS total_cases
    FROM tuberculosis_data
    GROUP BY region
),
global_cases AS (
    SELECT SUM(tb_cases) AS world_cases
    FROM tuberculosis_data
)
SELECT
    r.region,
    r.total_cases,
    ROUND((r.total_cases * 100.0 / g.world_cases), 2) AS pct_of_global_cases
FROM regional_cases r
CROSS JOIN global_cases g
ORDER BY pct_of_global_cases DESC;

--------------------------------------------------
-- 14. Population-adjusted TB incidence per 100,000
--------------------------------------------------
SELECT
    country,
    year,
    SUM(tb_cases) AS total_cases,
    SUM(population) AS total_population,
    ROUND((SUM(tb_cases) * 100000.0 / NULLIF(SUM(population), 0)), 2) AS cases_per_100k
FROM tuberculosis_data
GROUP BY country, year
ORDER BY cases_per_100k DESC;

--------------------------------------------------
-- 15. 3-year moving average of global TB cases
--------------------------------------------------
WITH yearly_cases AS (
    SELECT
        year,
        SUM(tb_cases) AS total_cases
    FROM tuberculosis_data
    GROUP BY year
)
SELECT
    year,
    total_cases,
    ROUND(
        AVG(total_cases) OVER (
            ORDER BY year
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_3yr_cases
FROM yearly_cases
ORDER BY year;
