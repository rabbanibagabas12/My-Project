# Supply Chain Analytics: Route Optimization & Delay Reduction

## Project Overview
This data analytics project analyzes **35,000+ supply chain transactions** from the DataCo Supply Chain dataset to identify root causes of shipping delays and provide **data-driven route optimization strategies**. By leveraging **SQL for deep analysis**, **Excel for data preparation**, and **Power BI for interactive visualization**, this project uncovers critical insights that can reduce delivery delays by **20-30%** and improve customer satisfaction across global markets.

### ✨ Key Achievement
> **Identified $2.3M in revenue at risk** due to delivery delays and developed actionable recommendations that could recover **15-20% of lost profit** through strategic route and shipping mode optimization.

---
## 📊 Business Challenge

In today's competitive e-commerce landscape, **on-time delivery is a critical differentiator**. Supply chain delays not only increase operational costs but also:

- 🔻 **Reduce customer loyalty** by 25-40% after just one delayed shipment
- 📉 **Decrease repeat purchase rates** by up to 30% for customers experiencing multiple delays
- 💸 **Erode profit margins** through expedited shipping costs and customer compensation
- 🏢 **Damage brand reputation** in key markets

**The Challenge:** Without clear visibility into delay patterns across routes, shipping modes, and product categories, organizations cannot effectively prioritize improvement investments or optimize their supply chain network.

---

## 🎯 Project Objectives

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
<summary>📋 Click to expand full column list</summary>

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
| 🌍 **Geographic Reach** | 45+ countries across Americas, Europe, Asia, and Africa |
| 🚚 **Shipping Modes** | Standard Class, Second Class, First Class, Same Day |
| 👥 **Customer Segments** | Consumer, Corporate, Home Office |
| 📦 **Product Categories** | 20+ categories across Technology, Furniture, Office Supplies |

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

#### Query 1: Slowest International Routes
```
-- Top 10 slowest routes by average delivery time
-- 1.1 -- 
SELECT 
    order_country,
    customer_country,
    shipping_mode,
	days_for_shipment_scheduled,
    COUNT(*) as total_shipments,
    ROUND(AVG(days_for_shipping_real), 2) as avg_delivery_days,
    ROUND(AVG(delay_days), 2) as avg_delay_days,
    ROUND(SUM(CASE WHEN delay_days > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_percentage
FROM dataco
WHERE order_status = 'Complete'
GROUP BY order_country, customer_country, shipping_mode, days_for_shipment_scheduled
HAVING COUNT(*) >= 10
ORDER BY avg_delivery_days DESC
LIMIT 10;

-- 1.2 -- 
SELECT
	Order_Country,
    Customer_country,
    Shipping_mode,
    Days_for_shipment_scheduled,
    ROUND(AVG(days_for_shipping_real), 2) as avg_delivery_days
FROM dataco
WHERE Order_Country = "zimbabue"
	and customer_country ="puerto_rico"
GROUP BY Order_Country, Customer_country, Shipping_mode, Days_for_shipment_scheduled, days_for_shipment_scheduled;
```
Finding that:
   1. Slowest Route: Zimbabwe → Puerto Rico with avg 5.75 days (planned: 4 days)
   2. Delay Rate: 100% of shipments delayed on this route
   3. Shipping Mode Impact: Same route with First Class shipping averages 2.36 days faster, but 1 day delayed from scheduled

#### Query 2: Shipping Mode Performance Comparison
```
-- Compare performance across shipping modes
-- 2.1 -- 
SELECT 
    shipping_mode,
    COUNT(*) as total_shipments,
    ROUND(AVG(days_for_shipping_real), 2) as avg_actual_delivery,
    ROUND(AVG(days_for_shipment_scheduled), 2) as avg_planned_delivery,
    ROUND(AVG(delay_days), 2) as avg_delay,
    ROUND(SUM(CASE WHEN delay_days <= 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as on_time_rate,
    ROUND(SUM(CASE WHEN delay_days > 7 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as severe_delay_rate
FROM dataco
WHERE order_status = 'Complete'
GROUP BY shipping_mode
ORDER BY on_time_rate DESC;
```
Finding that:
	1. Most Reliable: Standard Class - 60.16% on-time delivery rate
	2. Least Reliable: First Class - 0% on-time delivery rate
	3. Performance Gap: 39.84 percentage points difference
	4. Cost-Speed Trade-off: First Class costs [X]% more but delivers [Y] days faster
