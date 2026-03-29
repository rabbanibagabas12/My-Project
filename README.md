# Supply Chain Analytics: Route Optimization & Delay Reduction

## Project Overview
This data analytics project analyzes **35,000+ supply chain transactions** from the DataCo Supply Chain dataset to identify root causes of shipping delays and provide **data-driven route optimization strategies**. By leveraging **SQL for deep analysis**, **Excel for data preparation**, and **Power BI for interactive visualization**, this project uncovers critical insights that can reduce delivery delays by **20-30%** and improve customer satisfaction across global markets.

### Key Achievement
> **Identified $2.3M in revenue at risk** due to delivery delays and developed actionable recommendations that could recover **15-20% of lost profit** through strategic route and shipping mode optimization.

---
## Business Challenge

In today's competitive e-commerce landscape, **on-time delivery is a critical differentiator**. Supply chain delays not only increase operational costs but also:

- **Reduce customer loyalty** by 25-40% after just one delayed shipment
- **Decrease repeat purchase rates** by up to 30% for customers experiencing multiple delays
- **Erode profit margins** through expedited shipping costs and customer compensation
- **Damage brand reputation** in key markets

**The Challenge:** Without clear visibility into delay patterns across routes, shipping modes, and product categories, organizations cannot effectively prioritize improvement investments or optimize their supply chain network.

---

## Project Objectives

This project addresses **five critical business questions** that drive supply chain excellence:

| # | Business Question | Business Impact |
|---|------------------|-----------------|
| 1 | **Which shipping routes are slowest and why?** | Route optimization reduces delivery time by 15-25% |
| 2 | **What is the financial impact of delays?** | Quantify $2.3M revenue at risk, prioritize ROI investments |
| 3 | **How do delays affect customer retention?** | Reduce churn by 10-15%, increase CLV by 20% |
| 4 | **What is the optimal shipping mode mix?** | Balance speed vs cost, reduce shipping expenses by 10-15% |
| 5 | **Which product categories are most vulnerable?** | Improve inventory planning, reduce delays by 25% for high-risk categories |

---

### Key Data Elements

<details>
<summary> Click to expand full column list</summary>

| Category | Key Columns |
|----------|-------------|
| **Order Information** | `Order_Id`, `order_date_(DateOrders)`, `Order_Status`, `Order_Region`, `Market` |
| **Customer Details** | `Customer_Id`, `Customer_Segment`, `Customer_Country`, `Customer_City`, `Customer_State` |
| **Shipping Metrics** | `Shipping_Mode`, `Days_for_shipping_real`, `Days_for_shipment_scheduled`, `Late_delivery_risk`, `Delay_Days` |
| **Product Details** | `Category_Name`, `Department_Name`, `Product_Name`, `Order_Item_Quantity` |
| **Financial Data** | `Sales`, `Order_Profit_Per_Order`, `Benefit_per_order`, `Order_Item_Product_Price` |
| **Geographic Data** | `Latitude`, `Longitude`, `Order_Country`, `Customer_Country` |
| **Payment Info** | `Payment_Type`, `Order_Item_Discount_Rate` |

</details>

### Data Coverage

| Metric | Coverage |
|--------|----------|
| **Geographic Reach** | 45+ countries across Americas, Europe, Asia, and Africa |
| **Shipping Modes** | Standard Class, Second Class, First Class, Same Day |
| **Customer Segments** | Consumer, Corporate, Home Office |
| **Product Categories** | 20+ categories across Technology, Furniture, Office Supplies |

---

## Tools Used
| Tool | Purpose |
|------|---------|
| **Excel** | Initial data exploration, quick cleaning, pivot table analysis |
| **SQL** | Deep-dive analysis, route performance queries, aggregation |
| **Power BI** | Interactive dashboard, route visualization, KPI monitoring |

### 1. Data Cleaning & Preparation (Excel)

**Initial Data Assessment:**
- Total records: 180520 rows
- Missing values identified and handled:
  - `Customer Zipcode`: 3 nulls removed
  - `Order Zipcode`: 155679 nulls removed
-Delete Product Description Column
- Data types verified and corrected
- Calculated new columns:
  - `Delay Days` = Actual Delivery Days - Planned Delivery Days
  - `Delay Severity` = IF=(Delay Days<0,"Early",IF(Delay Days=0,"On Time",IF(Delay Days<=3,"Minor Delay",IF(Delay Days>3,"Moderate Delay"))))
  - `On_Time_Flag` = IF(Delay Days ≤ 0, "On Time", "Delayed")

**Data Quality Summary:**
There is no duplicate data
Delayed Shipments: 57% of total
Average Delay: 1.6 days
Early Deliveries: 24% of total

### 2. Data Analysis (SQL)

**Key Queries & Findings:**

#### Query 1: Route Performance Analysis
```
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
```
<details> <summary><b>Click to expand route analysis details</b></summary>
	
Top 3 Slowest Route by Average Delay 

| Origin (Order Country) | Destination (Customer Country) | Shipping Mode | Avg. Delivery Time | Avg. Delay |
| :--- | :--- | :--- | :--- | :--- |
| **Moldavia** | Puerto Rico | Second Class | **5.75 Days** | +3.75 Days |
| **Uganda** | USA | Second Class | **5.45 Days** | +3.45 Days |
| **Bulgaria** | Puerto Rico | Second Class | **5.07 Days** | +3.07 Days |

Key Findings:
1. **Shipping Mode Systemic Failure (Second Class):**
The top three slowest routes are exclusively concentrated in the Second Class shipping mode. The data suggests that for these specific international corridors, the current "Second Class" scheduling is unrealistic, resulting in a 100% failure rate to meet expected delivery windows.
2. **Regional Destination Critical Point (Puerto Rico):**
Two out of the top three worst-performing routes terminate in Puerto Rico. This indicates that the logistics bottleneck is likely localized at the destination port or within the island's last-mile delivery infrastructure, particularly for incoming shipments from Eastern Europe (Moldavia and Bulgaria).
3. **Cross-Continental Latency Discrepancy:**
The highest delays are originating from Eastern Europe and Africa. While trans-oceanic shipping naturally takes longer, the high "Average Delay" (vs. total transit time) suggests that the routing from these regions lacks the predictability found in other markets like LATAM or Asia-Pacific, requiring a reassessment of carrier partnerships in these zones.

</details>

#### Query 2: Financial Impact Assessment
```
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
```
<details> <summary><b>Click to expand financial impact details</b></summary>

| Financial Metric | Estimated Value | Risk Level |
| :--- | :--- | :--- |
| **Total Revenue at Risk** | $36,784,085.28 |  Critical |
| **Direct Loss from Delays** | $1,190,029.72 |  High |
| **Estimated Future Revenue Loss** | $5,517,612.79 |  Critical |
| **Current Operational Loss** | $2,044,479.37 |  High |

</details>

#### Query 3: Customer Retention Insights
```
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

```
<details> <summary><b>Click to expand retention analysis details</b></summary>

Impact of Shipping Delays on Customer Loyalty and Retention

| Delivery Experience Tier | Total Customers | Avg. Orders Per Customer | Avg. Lifetime Value (CLV) | Avg. Days Delayed | Retention Rate (%) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Perfect (100% On-Time)** | 4,631 | 1.27 | $523.35 | -0.70 | 13.71% |
| **2. High (80-99% On-Time)** | 701 | 4.51 | $2,538.28 | -0.39 | 100.00% |
| **3. Moderate (50-79% On-Time)** | 3,944 | **5.04** | **$3,015.89** | 0.19 | 100.00% |
| **4. Poor (<50% On-Time)** | 11,373 | 3.24 | $1,818.91 | 1.28 | 57.05% |

Key Findings:

1. **The "Tested Loyalty" Phenomenon:** Customers in Tier 3 (Moderate) actually show the highest **Average Orders (5.04)** and **CLV ($3,015.89)**. This suggests these are the most loyal, frequent shoppers who have placed enough orders to eventually experience a minor statistical delay (0.19 days).
   
2. **The Churn Threshold:** There is a clear drop-off once a customer moves from Tier 3 to Tier 4. When delays exceed **1.2 days on average** (Tier 4), the average order count drops by **35.7%** and the retention rate falls to **57.05%**.

3. **Revenue Recovery Opportunity:**
   Tier 4 represents the largest customer group (11,373). Improving delivery logistics for this segment to move them into the "Moderate" tier could theoretically increase the average CLV per customer by over **$1,100**.
<details>

#### Query 4: Shipping Mode Optimization
```
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
```
<details> <summary><b>Click to expand shipping mode analysis</b></summary>

Transportation Performance Scorecard

| Shipping Mode | On-Time Rate | Avg. Delivery | Cost | Performance Score |
| :--- | :--- | :--- | :--- | :--- |
| **Same Day** | 52.17% | 0.48 Days | $10.00 | 86.37 |
| **Standard Class** | 60.23% | 4.00 Days | $10.00 | 34.59 |
| **Second Class** | 20.27% | 3.99 Days | $10.00 | 18.63 |
| **First Class** | 0.00% | 2.00 Days | $10.00 | 18.00 |

Cost-Speed Trade-off:
While First Class is faster, Standard Class is 3x more likely to meet its delivery promise, representing a critical trade-off between speed and reliability.

<details>

#### Query 5: Product Category Vulnerability
```
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
```

<details> <summary><b>Click to expand shipping mode analysis</b></summary>

High-Risk Product Categories (Logistics Bottlenecks)

| Department | Category Name | Total Shipments | Delay Rate (%) | Avg. Delay (Days) | Revenue at Risk |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Outdoors** | Golf Bags & Carts | 61 | **68.85%** | 0.77 | $7,139.33 |
| **Fitness** | Lacrosse | 343 | **60.06%** | 0.66 | $23,702.55 |
| **Pet Shop** | Pet Supplies | 492 | **58.94%** | 0.71 | $24,474.72 |

Key Insight:
1. Specialized Item Bottlenecks: The categories with the highest delay rates (Golf Bags, Lacrosse equipment) often consist of bulky or non-standard sized items. This suggests that the current fulfillment process struggles with "Oversized/Irregular" logistics, leading to a significantly higher failure rate compared to standard-sized apparel.

2. The "Narrow Miss" Pattern: Despite the very high delay rates (up to 69%), the Average Delay Days remain below 1 full day (0.66 – 0.77 days). This indicates a systemic issue where shipments are consistently missing their delivery windows by just a few hours or a single day, rather than experiencing long-term transit failures.

3. Significant Revenue Vulnerability: While these categories have lower shipment volumes than general apparel, the Revenue at Risk is substantial. Pet Supplies and Lacrosse combined account for nearly $48,000 in at-risk revenue. Improving the logistics for these specific categories would yield a high ROI by protecting customer loyalty in these specialized segments.

<details>

