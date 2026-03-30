-- 2.1 --
-- Calculate financial loss by delay severity level
SELECT 
    Delay_Severity,
    COUNT(*) as affected_orders,
    ROUND(SUM(Sales), 2) as total_revenue_at_risk,
    ROUND(SUM(Order_Profit_Per_Order), 2) as actual_profit,
    ROUND(SUM(CASE 
        WHEN On_Time_Flag = 'On Time' THEN Order_Profit_Per_Order 
        ELSE Order_Profit_Per_Order * 0.7
    END), 2) as estimated_profit_if_ontime,
    ROUND(SUM(Order_Profit_Per_Order * 0.3), 2) as estimated_loss_from_delays,
    ROUND(AVG(Order_Item_Profit_Ratio), 4) as avg_profit_margin,
    ROUND(SUM(Sales) * 0.15, 2) as estimated_future_revenue_loss
FROM shipping_data
GROUP BY Delay_Severity
ORDER BY 
    CASE Delay_Severity
        WHEN 'Severe Delay' THEN 1
        WHEN 'Moderate Delay' THEN 2
        WHEN 'Minor Delay' THEN 3
        WHEN 'Early/On Time' THEN 4
    END;

-- 2.2 --
-- Identify high-value customers most affected by delays
SELECT 
    Customer_Id,
    Customer_Segment,
    Customer_Country,
    COUNT(*) as total_orders,
    ROUND(SUM(Sales), 2) as lifetime_value,
    ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate,
    ROUND(AVG(Delay_Days), 2) as avg_delay,
    ROUND(SUM(CASE WHEN Late_delivery_risk = 1 THEN Sales ELSE 0 END), 2) as revenue_at_risk,
    ROUND((SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) * (SUM(Sales) / 1000), 2) as retention_risk_score,
    CASE 
        WHEN SUM(Sales) > 10000 AND (SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 30 
            THEN 'Critical Risk - VIP'
        WHEN SUM(Sales) > 5000 AND (SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 20 
            THEN 'High Risk - Premium'
        WHEN SUM(Sales) > 1000 AND (SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 15 
            THEN 'Medium Risk'
        ELSE 'Low Risk'
    END as customer_risk_category
FROM shipping_data
GROUP BY Customer_Id, Customer_Segment, Customer_Country
HAVING COUNT(*) >= 5 AND SUM(CASE WHEN Late_delivery_risk = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) > 0
ORDER BY retention_risk_score DESC
LIMIT 50;

-- 2.3 --
-- Calculate potential ROI for different improvement scenarios
WITH delay_impact AS (
    SELECT 
        Department_Name,
        Category_Name,
        COUNT(*) as orders_affected,
        ROUND(SUM(Sales), 2) as revenue_impacted,
        ROUND(SUM(Order_Profit_Per_Order), 2) as profit_impacted,
        ROUND(AVG(Delay_Days), 2) as avg_delay_days
    FROM shipping_data
    WHERE Late_delivery_risk = 1
    GROUP BY Department_Name, Category_Name
),
improvement_scenarios AS (
    SELECT 
        Department_Name,
        Category_Name,
        orders_affected,
        revenue_impacted,
        profit_impacted,
        avg_delay_days,
        ROUND(profit_impacted * 0.25, 2) as roi_25_percent,
        ROUND(profit_impacted * 0.50, 2) as roi_50_percent,
        ROUND(profit_impacted * 0.75, 2) as roi_75_percent,
        CASE 
            WHEN avg_delay_days > 10 THEN ROUND(profit_impacted * 0.3, 2)
            WHEN avg_delay_days > 5 THEN ROUND(profit_impacted * 0.2, 2)
            ELSE ROUND(profit_impacted * 0.1, 2)
        END as estimated_investment
    FROM delay_impact
)
SELECT 
    Department_Name,
    Category_Name,
    orders_affected,
    profit_impacted as current_loss,
    roi_25_percent as profit_recovery_25,
    roi_50_percent as profit_recovery_50,
    roi_75_percent as profit_recovery_75,
    estimated_investment,
    ROUND((roi_50_percent - estimated_investment) / estimated_investment * 100, 2) as roi_percentage,
    RANK() OVER (ORDER BY (roi_50_percent - estimated_investment) DESC) as investment_priority
FROM improvement_scenarios
WHERE profit_impacted > 5000
ORDER BY investment_priority
LIMIT 20;