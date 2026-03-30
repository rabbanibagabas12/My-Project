-- 5.1 --
-- Create comprehensive delay vulnerability index for products
WITH category_stats AS (
    SELECT 
        Department_Name,
        Category_Name,
        COUNT(*) as total_shipments,
        ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
        ROUND(AVG(Delay_Days), 2) as avg_delay_days,
        ROUND(STDDEV(Delay_Days), 2) as delay_variability,
        ROUND(AVG(Order_Item_Quantity), 2) as avg_quantity,
        ROUND(SUM(Sales), 2) as total_revenue,
        ROUND(AVG(Order_Profit_Per_Order), 2) as avg_profit,
        -- Calculate complexity score (higher quantity = more complex)
        ROUND(AVG(Order_Item_Quantity) / NULLIF(MAX(AVG(Order_Item_Quantity)) OVER (), 0) * 100, 2) as complexity_score
    FROM shipping_data
    GROUP BY Department_Name, Category_Name
    HAVING COUNT(*) >= 30
),
vulnerability_index AS (
    SELECT 
        Department_Name,
        Category_Name,
        total_shipments,
        delay_rate,
        avg_delay_days,
        delay_variability,
        total_revenue,
        avg_profit,
        complexity_score,
        -- Calculate vulnerability index (0-100)
        ROUND((delay_rate * 0.4) + 
              (avg_delay_days / NULLIF(MAX(avg_delay_days) OVER (), 0) * 100 * 0.3) +
              (delay_variability / NULLIF(MAX(delay_variability) OVER (), 0) * 100 * 0.2) +
              (complexity_score * 0.1), 2) as vulnerability_index
    FROM category_stats
)
SELECT 
    Department_Name,
    Category_Name,
    total_shipments,
    delay_rate,
    avg_delay_days,
    delay_variability,
    total_revenue,
    ROUND(total_revenue * delay_rate / 100, 2) as revenue_at_risk,
    vulnerability_index,
    CASE 
        WHEN vulnerability_index >= 80 THEN 'Critical - Immediate Action'
        WHEN vulnerability_index >= 60 THEN 'High Priority'
        WHEN vulnerability_index >= 40 THEN 'Medium Priority'
        WHEN vulnerability_index >= 20 THEN 'Low Priority'
        ELSE 'Stable'
    END as priority_level,
    RANK() OVER (ORDER BY vulnerability_index DESC) as risk_rank
FROM vulnerability_index
ORDER BY vulnerability_index DESC
LIMIT 30;

-- 5.2 --
-- Analyze seasonal delay patterns for high-risk categories
WITH high_risk_categories AS (
    SELECT Category_Name
    FROM shipping_data
    GROUP BY Category_Name
    HAVING SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 25
),
monthly_category_performance AS (
    SELECT 
        hrc.Category_Name,
        MONTH(s.order_date) as month_num,
        MONTHNAME(s.order_date) as month_name,
        COUNT(*) as shipments,
        ROUND(SUM(CASE WHEN s.Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
        ROUND(AVG(s.Delay_Days), 2) as avg_delay_days,
        ROUND(SUM(s.Sales), 2) as monthly_revenue
    FROM shipping_data s
    JOIN high_risk_categories hrc ON s.Category_Name = hrc.Category_Name
    GROUP BY hrc.Category_Name, month_num, month_name
),
seasonal_patterns AS (
    SELECT 
        Category_Name,
        month_name,
        month_num,
        shipments,
        delay_rate,
        avg_delay_days,
        monthly_revenue,
        ROUND(delay_rate / NULLIF(AVG(delay_rate) OVER (PARTITION BY Category_Name), 0) * 100, 2) as seasonal_index
    FROM monthly_category_performance
)
SELECT 
    Category_Name,
    month_name,
    shipments,
    delay_rate,
    avg_delay_days,
    monthly_revenue,
    seasonal_index,
    CASE 
        WHEN seasonal_index > 150 THEN 'Peak Delay Season'
        WHEN seasonal_index > 120 THEN 'High Delay Season'
        WHEN seasonal_index < 80 THEN 'Low Delay Season'
        ELSE 'Normal Season'
    END as season_category
FROM seasonal_patterns
ORDER BY Category_Name, month_num;

-- 5.3 --
-- Generate actionable recommendations based on category characteristics
WITH category_problems AS (
    SELECT 
        Department_Name,
        Category_Name,
        COUNT(*) as total_shipments,
        ROUND(SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
        ROUND(AVG(Delay_Days), 2) as avg_delay,
        ROUND(AVG(Order_Item_Quantity), 2) as avg_quantity,
        ROUND(AVG(Order_Item_Product_Price), 2) as avg_unit_price,
        CASE 
            WHEN AVG(Order_Item_Quantity) > 5 AND SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 30 
                THEN 'Bulk Order Processing'
            WHEN AVG(Delay_Days) > 10 AND SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 25 
                THEN 'Severe Transit Delays'
            WHEN AVG(Delay_Days) BETWEEN 3 AND 10 AND SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 20 
                THEN 'Moderate Handling Delays'
            WHEN AVG(Order_Item_Product_Price) > 500 AND SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 15 
                THEN 'High-Value Item Security'
            ELSE 'General Operational Issues'
        END as primary_issue
    FROM shipping_data
    GROUP BY Department_Name, Category_Name
    HAVING COUNT(*) >= 30 AND SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 15
)
SELECT 
    Department_Name,
    Category_Name,
    total_shipments,
    delay_rate,
    avg_delay,
    primary_issue,
    CASE primary_issue
        WHEN 'Bulk Order Processing' THEN 'Implement batch processing and optimize warehouse layout for pallets'
        WHEN 'Severe Transit Delays' THEN 'Establish regional distribution centers and renegotiate carrier SLAs'
        WHEN 'Moderate Handling Delays' THEN 'Cross-train staff and implement picking automation'
        WHEN 'High-Value Item Security' THEN 'Secure packaging protocols and signature-required delivery'
        ELSE 'Conduct process audit and enhance staff training'
    END as recommendation_short_term,
    CASE 
        WHEN primary_issue = 'Severe Transit Delays' THEN 'High (Infrastructure Change)'
        WHEN primary_issue = 'Bulk Order Processing' THEN 'Medium (Process Redesign)'
        ELSE 'Low (Operational Tweak)'
    END as implementation_complexity,
    ROUND((delay_rate / 100) * avg_unit_price * total_shipments * 0.3, 2) as est_annual_savings
FROM category_problems
ORDER BY est_annual_savings DESC;