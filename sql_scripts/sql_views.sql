-- =========================================================
-- INFOSYS PERFORMANCE ANALYTICS - MASTER SQL SCHEMA & VIEWS
-- =========================================================

-- =========================================================
-- 1. TABLE CREATION 
-- =========================================================
CREATE TABLE IF NOT EXISTS fact_segments (
    Quarter VARCHAR(10),
    Segment VARCHAR(100),
    Percentage DECIMAL(15, 4),
    Quarter_Num VARCHAR(2),
    Fiscal_Year INT
);

-- =========================================================
-- 2. FINANCIAL PERFORMANCE & MARGIN VIEWS
-- =========================================================

-- Annual Financial Summary
CREATE OR REPLACE VIEW vw_annual_financial_summary AS
WITH quarterly_summary AS (
    SELECT 
        fiscal_year,
        period_end_date,
        quarter_num,
        MAX(CASE WHEN TRIM(Metrics) = 'Revenues' THEN amount ELSE 0 END) AS revenue,
        MAX(CASE WHEN TRIM(Metrics) = 'Gross Profit' THEN amount ELSE 0 END) AS gross_profit,
        MAX(CASE WHEN TRIM(Metrics) LIKE '%Operating profit%' AND TRIM(Metrics) NOT LIKE '%Adjusted%' THEN amount ELSE 0 END) AS operating_profit
    FROM fact_financials
    GROUP BY fiscal_year, period_end_date, quarter_num
)
SELECT 
    fiscal_year,
    SUM(revenue) AS total_annual_revenue,
    SUM(gross_profit) AS total_gross_profit,
    SUM(operating_profit) AS total_operating_profit,
    ROUND(
        (SUM(operating_profit) / NULLIF(SUM(revenue), 0)) * 100, 2
    ) AS full_year_operating_margin_pct
FROM quarterly_summary
GROUP BY fiscal_year
ORDER BY fiscal_year DESC;

-- Operating Margin Trajectory & Cost of Sales Ratio
CREATE OR REPLACE VIEW vw_operating_margins AS
SELECT 
    period_end_date,
    fiscal_year,
    quarter_num,
    MAX(CASE WHEN TRIM(Metrics) = 'Revenues' THEN amount END) AS revenue,
    MAX(CASE WHEN TRIM(Metrics) = 'Cost of sales' THEN amount END) AS cost_of_sales,
    MAX(CASE WHEN TRIM(Metrics) LIKE '%Operating profit%' AND TRIM(Metrics) NOT LIKE '%Adjusted%' THEN amount END) AS operating_profit,
    ROUND(
        (MAX(CASE WHEN TRIM(Metrics) LIKE '%Operating profit%' AND TRIM(Metrics) NOT LIKE '%Adjusted%' THEN amount END) / 
         NULLIF(MAX(CASE WHEN TRIM(Metrics) = 'Revenues' THEN amount END), 0)) * 100, 2
    ) AS operating_margin_pct,
    ROUND(
        (MAX(CASE WHEN TRIM(Metrics) = 'Cost of sales' THEN amount END) / 
         NULLIF(MAX(CASE WHEN TRIM(Metrics) = 'Revenues' THEN amount END), 0)) * 100, 2
    ) AS cost_to_revenue_pct
FROM fact_financials
GROUP BY period_end_date, fiscal_year, quarter_num
ORDER BY period_end_date DESC;

-- Quarterly Revenue YoY Growth Rate
CREATE OR REPLACE VIEW vw_quarterly_revenue_growth AS
WITH revenue_series AS (
    SELECT 
        period_end_date,
        fiscal_year,
        quarter_num,
        amount AS revenue_inr_crore,
        -- Fetch revenue from 4 quarters ago (same quarter last year)
        LAG(amount, 4) OVER (ORDER BY period_end_date) AS prev_year_revenue
    FROM fact_financials
    WHERE Metrics = 'Revenues'
)
SELECT 
    period_end_date,
    fiscal_year,
    quarter_num,
    revenue_inr_crore,
    prev_year_revenue,
    ROUND(((revenue_inr_crore - prev_year_revenue) / prev_year_revenue) * 100, 2) AS yoy_growth_pct
FROM revenue_series
ORDER BY period_end_date DESC;

-- =========================================================
-- 3. WORKFORCE & DELIVERY EFFICIENCY VIEW
-- =========================================================
CREATE OR REPLACE VIEW vw_workforce_metrics AS
SELECT 
    Quarter,
    Fiscal_Year,
    Quarter_Num,
    
    -- Dynamically generate the end-of-quarter date
    DATE(
        CASE 
            WHEN Quarter_Num IN ('1', 'Q1') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-06-30')
            WHEN Quarter_Num IN ('2', 'Q2') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-09-30')
            WHEN Quarter_Num IN ('3', 'Q3') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-12-31')
            WHEN Quarter_Num IN ('4', 'Q4') THEN CONCAT(CAST(Fiscal_Year AS CHAR), '-03-31')
        END
    ) AS period_end_date,

    -- Headcount
    MAX(CASE WHEN Metric = 'Total Employees (Consolidated)' THEN Amount END) AS total_employees,
    MAX(CASE WHEN Metric = 'Voluntary Attrition % (LTM - IT Services)' THEN Amount END) AS attrition_pct,
    MAX(CASE WHEN Metric = 'Women employees (%)' THEN Amount END) AS diversity_pct,
    
    -- Use MAX with a filter to isolate the true percentages (between 0% and 100%)
    MAX(CASE WHEN Metric = 'Including trainees' AND Amount BETWEEN 0 AND 1 THEN Amount END) AS utilization_pct,
    MAX(CASE WHEN Metric = 'Onsite' AND Amount BETWEEN 0 AND 1 THEN Amount END) AS onsite_effort_pct,
    MAX(CASE WHEN Metric = 'Offshore' AND Amount BETWEEN 0 AND 1 THEN Amount END) AS offshore_effort_pct

FROM fact_workforce
WHERE Quarter NOT LIKE 'FY%' 
GROUP BY Quarter, Fiscal_Year, Quarter_Num;

-- =========================================================
-- 4. GEOGRAPHIC & INDUSTRY SEGMENTS VIEW
-- =========================================================
CREATE OR REPLACE VIEW vw_segment_metrics AS
SELECT 
    Quarter,
    Fiscal_Year,
    Quarter_Num,
    
    DATE(
        CASE 
            WHEN Quarter_Num IN ('1', 'Q1') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-06-30')
            WHEN Quarter_Num IN ('2', 'Q2') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-09-30')
            WHEN Quarter_Num IN ('3', 'Q3') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-12-31')
            WHEN Quarter_Num IN ('4', 'Q4') THEN CONCAT(CAST(Fiscal_Year AS CHAR), '-03-31')
        END
    ) AS period_end_date,

    Segment,
    Percentage AS revenue_share_pct

FROM fact_segments
WHERE Quarter NOT LIKE 'FY%'
GROUP BY Quarter, Fiscal_Year, Quarter_Num, Segment, Percentage;

-- =========================================================
-- 5. CLIENT PORTFOLIO & CONCENTRATION VIEW
-- =========================================================
CREATE OR REPLACE VIEW vw_client_metrics AS
SELECT 
    Quarter,
    Fiscal_Year,
    Quarter_Num,
    
    -- Dynamically generate the end-of-quarter date
    DATE(
        CASE 
            WHEN Quarter_Num IN ('1', 'Q1') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-06-30')
            WHEN Quarter_Num IN ('2', 'Q2') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-09-30')
            WHEN Quarter_Num IN ('3', 'Q3') THEN CONCAT(CAST(Fiscal_Year - 1 AS CHAR), '-12-31')
            WHEN Quarter_Num IN ('4', 'Q4') THEN CONCAT(CAST(Fiscal_Year AS CHAR), '-03-31')
        END
    ) AS period_end_date,

    -- Client Counts (Using MAX)
    MAX(CASE WHEN Metric = 'Active clients' THEN Amount END) AS total_active_clients,
    MAX(CASE WHEN Metric = 'Added during the quarter' THEN Amount END) AS new_clients_added,
    MAX(CASE WHEN Metric = '100 Million dollar +' THEN Amount END) AS clients_100m,
    MAX(CASE WHEN Metric = '50 Million dollar +' THEN Amount END) AS clients_50m,
    
    -- Concentration Percentages (Ensure they are decimals between 0 and 1)
    MAX(CASE WHEN Metric = 'Top 5 clients' AND Amount BETWEEN 0 AND 1 THEN Amount END) AS top_5_revenue_pct,
    MAX(CASE WHEN Metric = 'Top 10 clients' AND Amount BETWEEN 0 AND 1 THEN Amount END) AS top_10_revenue_pct

FROM fact_clients
WHERE Quarter NOT LIKE 'FY%'
GROUP BY Quarter, Fiscal_Year, Quarter_Num;
