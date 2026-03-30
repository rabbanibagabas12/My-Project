-- 3.1 --
-- Analyze how delivery experience affects customer loyalty
SELECT 
    Delivery_Experience_Tier,
    COUNT(Customer_Id) AS Total_Customers,
    ROUND(AVG(Total_Orders), 2) AS Avg_Orders_Per_Customer,
    ROUND(AVG(Total_Sales), 2) AS Avg_Lifetime_Value,
    ROUND(AVG(Avg_Delay_Days), 2) AS Avg_Days_Delayed,
    ROUND(SUM(CASE WHEN Total_Orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(Customer_Id), 2) AS Retention_Rate_Pct
FROM (
    SELECT 
        Customer_Id,
        COUNT(DISTINCT Order_Id) AS Total_Orders,
        SUM(Sales) AS Total_Sales,
        AVG(CAST(Delay_Days AS FLOAT)) AS Avg_Delay_Days,
        CASE 
            WHEN SUM(CASE WHEN On_Time_Flag = 'On Time' THEN 1 ELSE 0 END) * 1.0 / COUNT(Order_Id) = 1 
                THEN '1. Perfect (100% On-Time)'
            WHEN SUM(CASE WHEN On_Time_Flag = 'On Time' THEN 1 ELSE 0 END) * 1.0 / COUNT(Order_Id) >= 0.8 
                THEN '2. High (80-99% On-Time)'
            WHEN SUM(CASE WHEN On_Time_Flag = 'On Time' THEN 1 ELSE 0 END) * 1.0 / COUNT(Order_Id) >= 0.5 
                THEN '3. Moderate (50-79% On-Time)'
            ELSE '4. Poor (<50% On-Time)'
        END AS Delivery_Experience_Tier
    FROM shipping_data
    GROUP BY Customer_Id
) AS Customer_Aggregates
GROUP BY Delivery_Experience_Tier
ORDER BY Delivery_Experience_Tier ASC;

-- 3.2 --
-- Identify customers at risk of churn due to delivery issues
WITH latest_info AS (
    SELECT MAX(order_date) as max_db_date FROM shipping_data
),
customer_delay_patterns AS (
    SELECT 
        Customer_Id,
        Customer_Segment,
        COUNT(*) as total_orders,
        ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as overall_delay_rate,
        -- Identify recent delay trend (last 90 days of the dataset)
        ROUND(SUM(CASE 
            WHEN order_date >= DATE_SUB((SELECT max_db_date FROM latest_info), INTERVAL 90 DAY) AND Late_delivery_risk = 1 THEN 1 
            ELSE 0 
        END) * 100.0 / 
        NULLIF(SUM(CASE WHEN order_date >= DATE_SUB((SELECT max_db_date FROM latest_info), INTERVAL 90 DAY) THEN 1 ELSE 0 END), 0), 2) as recent_delay_rate,
        SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) as total_delays,
        ROUND(AVG(Delay_Days), 2) as avg_delay_days,
        MAX(Delay_Days) as max_delay,
        MAX(order_date) as last_order_date,
        DATEDIFF((SELECT max_db_date FROM latest_info), MAX(order_date)) as days_since_last_order,
        AVG(Sales) as individual_avg_sales
    FROM shipping_data
    GROUP BY Customer_Id, Customer_Segment
    HAVING total_orders >= 3
)
SELECT 
    Customer_Id,
    Customer_Segment,
    total_orders,
    overall_delay_rate,
    recent_delay_rate,
    avg_delay_days,
    days_since_last_order,
    CASE 
        WHEN days_since_last_order > 180 THEN 'Already Churned'
        WHEN days_since_last_order > 90 AND recent_delay_rate > 50 THEN 'High Churn Risk - Recent Delays'
        WHEN recent_delay_rate > overall_delay_rate + 20 THEN 'Increasing Churn Risk - Deteriorating Service'
        WHEN overall_delay_rate > 30 AND recent_delay_rate > 30 THEN 'Medium Churn Risk - Consistent Delays'
        WHEN overall_delay_rate > 15 THEN 'Low Churn Risk - Occasional Delays'
        ELSE 'Loyal Customer'
    END as churn_risk_category,
    CASE 
        WHEN recent_delay_rate > 50 THEN ROUND(individual_avg_sales * 0.3, 2)
        WHEN recent_delay_rate > 30 THEN ROUND(individual_avg_sales * 0.2, 2)
        ELSE ROUND(individual_avg_sales * 0.1, 2)
    END as suggested_recovery_investment
FROM customer_delay_patterns
WHERE overall_delay_rate > 0
ORDER BY 
    CASE 
        WHEN days_since_last_order > 180 THEN 5
        WHEN days_since_last_order > 90 AND recent_delay_rate > 50 THEN 4
        WHEN recent_delay_rate > overall_delay_rate + 20 THEN 3
        WHEN overall_delay_rate > 30 THEN 2
        ELSE 1
    END DESC,
    overall_delay_rate DESC;
    
-- 3.3 --
-- Analyze which customer segments are most sensitive to delivery delays
SELECT 
    Customer_Segment,
    COUNT(DISTINCT Customer_Id) as unique_customers,
    ROUND(SUM(total_segment_sales), 2) as total_revenue,
    
    ROUND(SUM(CASE 
        WHEN has_recent_delay = 1 THEN 1 ELSE 0 
    END) * 100.0 / NULLIF(COUNT(*), 0), 2) as delayed_customer_rate,

    ROUND(AVG(CASE WHEN has_any_delay = 1 THEN total_orders ELSE NULL END), 2) as avg_orders_delayed_customers,
    
    ROUND(AVG(CASE WHEN has_any_delay = 0 THEN total_orders ELSE NULL END), 2) as avg_orders_undelayed_customers,

    ROUND((AVG(CASE WHEN has_any_delay = 1 THEN total_orders ELSE NULL END) - 
           AVG(CASE WHEN has_any_delay = 0 THEN total_orders ELSE NULL END)) / 
           NULLIF(AVG(CASE WHEN has_any_delay = 0 THEN total_orders ELSE NULL END), 0) * 100, 2) as sensitivity_score
FROM (
    SELECT 
        Customer_Segment,
        Customer_Id,
        COUNT(*) as total_orders,
        SUM(Sales) as total_segment_sales,
        -- Check if customer had any delay ever
        MAX(CASE WHEN Delay_Days > 0 THEN 1 ELSE 0 END) as has_any_delay,
        -- Check if customer had a delay in the last 365 days of the dataset
        MAX(CASE 
            WHEN Delay_Days > 0 AND order_date >= DATE_SUB((SELECT MAX(order_date) FROM shipping_data), INTERVAL 365 DAY) 
            THEN 1 ELSE 0 
        END) as has_recent_delay
    FROM shipping_data
    GROUP BY Customer_Segment, Customer_Id
) segment_data
GROUP BY Customer_Segment
ORDER BY sensitivity_score DESC;