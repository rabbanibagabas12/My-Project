-- 1.1 --
-- Identify high-impact routes by delay severity and volume
SELECT 
    Order_Country,
    Customer_Country,
    Market,
    COUNT(*) as total_shipments,
    ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
    ROUND(AVG(Delay_Days), 2) as avg_delay_days,
    ROUND(SUM(Sales), 2) as total_revenue_impacted,
    ROUND(AVG(Order_Profit_Per_Order), 2) as avg_profit_loss,
    CASE 
        WHEN COUNT(*) >= 100 AND (SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 30 
            THEN 'Critical - Immediate Action'
        WHEN COUNT(*) >= 50 AND (SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 20 
            THEN 'High Priority'
        WHEN COUNT(*) >= 20 AND (SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 15 
            THEN 'Medium Priority'
        ELSE 'Monitor'
    END as priority_level
FROM shipping_data
GROUP BY Order_Country, Customer_Country, Market
HAVING COUNT(*) >= 20
ORDER BY delay_rate DESC, total_shipments DESC
LIMIT 20;

-- 1.2 --
-- Identify specific cities with severe delay issues
SELECT 
    Customer_Country,
    Customer_State,
    Customer_City,
    COUNT(*) as shipments,
    ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
    ROUND(AVG(Delay_Days), 2) as avg_delay_days,
    ROUND(MAX(Delay_Days), 2) as worst_delay,
    ROUND(AVG(Sales), 2) as avg_order_value,
    ROUND(SUM(CASE WHEN On_Time_Flag = 'On Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as on_time_rate,
    RANK() OVER (ORDER BY SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) DESC) as delay_rank
FROM shipping_data
GROUP BY Customer_Country, Customer_State, Customer_City
HAVING COUNT(*) >= 15 AND delay_rate > 20
ORDER BY delay_rate DESC
LIMIT 30;

-- 1.3 --
-- Analyze which shipping modes work best for problematic routes
WITH high_delay_routes AS (
    SELECT 
        Order_Country,
        Customer_Country
    FROM shipping_data
    GROUP BY Order_Country, Customer_Country
    HAVING SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 25
),
route_stats AS (
    SELECT 
        sd.Order_Country,
        sd.Customer_Country,
        sd.Shipping_Mode,
        COUNT(*) as shipments,
        SUM(CASE WHEN sd.Late_delivery_risk = 1 THEN 1 ELSE 0 END) as delayed_count,
        ROUND(AVG(sd.Days_for_shipping_real), 2) as avg_delivery_days,
        ROUND(AVG(sd.Delay_Days), 2) as avg_delay
    FROM shipping_data sd
    INNER JOIN high_delay_routes hdr 
        ON sd.Order_Country = hdr.Order_Country 
        AND sd.Customer_Country = hdr.Customer_Country
    GROUP BY sd.Order_Country, sd.Customer_Country, sd.Shipping_Mode
    HAVING COUNT(*) >= 10
)
SELECT 
    Order_Country,
    Customer_Country,
    Shipping_Mode,
    shipments,
    ROUND(delayed_count * 100.0 / shipments, 2) as delay_rate,
    avg_delivery_days,
    avg_delay,
    ROUND(avg_delay - (
        SELECT MIN(avg_delay) 
        FROM route_stats rs2 
        WHERE rs2.Order_Country = rs1.Order_Country 
        AND rs2.Customer_Country = rs1.Customer_Country
    ), 2) as improvement_potential
FROM route_stats rs1
ORDER BY delay_rate DESC;