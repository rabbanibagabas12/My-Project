-- 4.1 --
-- Create comprehensive shipping mode scorecard
WITH mode_metrics AS (
    SELECT 
        Shipping_Mode,
        COUNT(*) as total_shipments,
        ROUND(AVG(Days_for_shipping_real), 2) as avg_delivery_days,
        ROUND(AVG(Days_for_shipment_scheduled), 2) as avg_planned_days,
        ROUND(SUM(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
        ROUND(AVG(Delay_Days), 2) as avg_delay_days,
        ROUND(AVG(Sales), 2) as avg_order_value,
        ROUND(AVG(Order_Profit_Per_Order), 2) as avg_profit
    FROM shipping_data
    GROUP BY Shipping_Mode
),
median_calc AS (
    SELECT 
        Shipping_Mode,
        AVG(Days_for_shipping_real) as median_delivery_days
    FROM (
        SELECT 
            Shipping_Mode, 
            Days_for_shipping_real,
            ROW_NUMBER() OVER (PARTITION BY Shipping_Mode ORDER BY Days_for_shipping_real) as row_num,
            COUNT(*) OVER (PARTITION BY Shipping_Mode) as total_count
        FROM shipping_data
    ) sub
    WHERE row_num IN (FLOOR((total_count + 1) / 2), CEIL((total_count + 1) / 2))
    GROUP BY Shipping_Mode
),
mode_cost_estimates AS (
    SELECT 
        Shipping_Mode,
        CASE 
            WHEN Shipping_Mode = 'Same Day' THEN 25.00
            WHEN Shipping_Mode = 'First Class' THEN 15.00
            WHEN Shipping_Mode = 'Second Class' THEN 8.00
            WHEN Shipping_Mode = 'Standard Class' THEN 5.00
            ELSE 10.00
        END as estimated_cost_per_order,
        CASE 
            WHEN Shipping_Mode = 'Same Day' THEN 'Premium'
            WHEN Shipping_Mode = 'First Class' THEN 'Express'
            WHEN Shipping_Mode = 'Second Class' THEN 'Standard'
            WHEN Shipping_Mode = 'Standard Class' THEN 'Economy'
            ELSE 'Mixed'
        END as service_tier
    FROM shipping_data
    GROUP BY Shipping_Mode
)
SELECT 
    mm.Shipping_Mode,
    me.service_tier,
    mm.total_shipments,
    mm.avg_delivery_days,
    mc.median_delivery_days,
    mm.delay_rate,
    mm.avg_delay_days,
    me.estimated_cost_per_order,
    ROUND((me.estimated_cost_per_order - 5.00) / NULLIF(5.00 - mm.avg_delivery_days, 0), 2) as cost_per_day_saved,
    ROUND((100 - mm.delay_rate) * 0.4 + (1 / NULLIF(mm.avg_delivery_days, 0)) * 100 * 0.3 + (1 / NULLIF(me.estimated_cost_per_order, 0)) * 100 * 0.3, 2) as performance_score
FROM mode_metrics mm
JOIN mode_cost_estimates me ON mm.Shipping_Mode = me.Shipping_Mode
JOIN median_calc mc ON mm.Shipping_Mode = mc.Shipping_Mode
ORDER BY performance_score DESC;

-- 4.2 -- 
-- Determine best shipping mode based on order value, product type, and urgency
SELECT 
    CASE 
        WHEN Sales < 100 THEN 'Low Value (<$100)'
        WHEN Sales < 500 THEN 'Medium Value ($100-$500)'
        WHEN Sales < 1000 THEN 'High Value ($500-$1000)'
        ELSE 'Premium Value (>$1000)'
    END as order_value_tier,
    Department_Name,
    Shipping_Mode,
    COUNT(*) as shipments,
    ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
    ROUND(AVG(Days_for_shipping_real), 2) as avg_delivery_days,
    ROUND(AVG(Order_Profit_Per_Order), 2) as avg_profit,
    -- Calculate mode suitability score
    ROUND((100 - (SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))) * 
          (AVG(Order_Profit_Per_Order) / 100), 2) as suitability_score
FROM shipping_data
GROUP BY 
    CASE 
        WHEN Sales < 100 THEN 'Low Value (<$100)'
        WHEN Sales < 500 THEN 'Medium Value ($100-$500)'
        WHEN Sales < 1000 THEN 'High Value ($500-$1000)'
        ELSE 'Premium Value (>$1000)'
    END,
    Department_Name,
    Shipping_Mode
HAVING COUNT(*) >= 20
ORDER BY order_value_tier, suitability_score DESC;

-- 4.3 --
-- Calculate potential benefits of switching shipping modes for problematic routes
WITH current_performance AS (
    SELECT 
        Order_Country,
        Customer_Country,
        Shipping_Mode,
        COUNT(*) as shipment_count,
        ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as current_delay_rate,
        ROUND(AVG(Days_for_shipping_real), 2) as current_delivery_days
    FROM shipping_data
    GROUP BY Order_Country, Customer_Country, Shipping_Mode
    HAVING COUNT(*) >= 10
),
alternative_modes AS (
    SELECT 
        cp.Order_Country,
        cp.Customer_Country,
        cp.Shipping_Mode as current_mode,
        alt.Shipping_Mode as alternative_mode,
        cp.current_delay_rate,
        cp.current_delivery_days,
        ROUND(AVG(CASE WHEN alt.Shipping_Mode = s.Shipping_Mode THEN 
            CASE WHEN s.Late_delivery_risk = 1 THEN 1 ELSE 0 END * 100.0 
        END), 2) as alt_delay_rate,
        ROUND(AVG(CASE WHEN alt.Shipping_Mode = s.Shipping_Mode THEN s.Days_for_shipping_real END), 2) as alt_delivery_days
    FROM current_performance cp
    CROSS JOIN (SELECT DISTINCT Shipping_Mode FROM shipping_data) alt
    JOIN shipping_data s ON cp.Order_Country = s.Order_Country 
        AND cp.Customer_Country = s.Customer_Country
        AND alt.Shipping_Mode = s.Shipping_Mode
    WHERE alt.Shipping_Mode != cp.Shipping_Mode
    GROUP BY cp.Order_Country, cp.Customer_Country, cp.Shipping_Mode, alt.Shipping_Mode
)
SELECT 
    Order_Country,
    Customer_Country,
    current_mode,
    alternative_mode,
    current_delay_rate,
    alt_delay_rate,
    ROUND(current_delay_rate - alt_delay_rate, 2) as delay_rate_improvement,
    current_delivery_days,
    alt_delivery_days,
    ROUND(current_delivery_days - alt_delivery_days, 2) as days_saved,
    CASE 
        WHEN alt_delay_rate < current_delay_rate - 10 THEN 'Strongly Recommended'
        WHEN alt_delay_rate < current_delay_rate - 5 THEN 'Recommended'
        WHEN alt_delay_rate < current_delay_rate THEN 'Consider'
        ELSE 'Not Recommended'
    END as switch_recommendation
FROM alternative_modes
WHERE current_delay_rate > 20
ORDER BY delay_rate_improvement DESC
LIMIT 30;