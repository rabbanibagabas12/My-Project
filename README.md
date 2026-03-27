# Supply Chain Analytics: Shipping Route Optimization & Delay Analysis

## Project Overview
This data analytics project analyzes the DataCo Supply Chain dataset to identify the slowest shipping routes and uncover root causes of delivery delays. By examining shipping performance across different routes, carriers, and product categories, this project provides actionable recommendations for route optimization and vendor selection to improve on-time delivery rates.

**Business Value:** Reduce shipping delays by 20-30% through data-driven route and vendor optimization strategies.

## Business Questions
1. **Which shipping routes experience the longest delivery times?**
   - Identify top 10 slowest origin-destination pairs
   - Compare planned vs actual delivery times
   - Analyze by shipping mode performance

2. **What are the primary factors causing shipping delays?**
   - Shipping mode impact analysis
   - Product category influence
   - Geographic patterns and regional performance
   - Seasonal trends and timing factors
   - Customer segment analysis

3. **How do different shipping modes compare in reliability?**
   - Standard vs Express vs Same-day delivery performance
   - Cost vs speed trade-off analysis

4. **What alternative routes or shipping strategies can improve delivery efficiency?**
   - Route substitution recommendations
   - Shipping mode optimization
   - Regional distribution strategies

## Dataset
- **Source**: Data Co Supply Chain Dataset (Kaggle)
- **Time Period**: 2015-2018
- **Size**: 180520 rows × 55 columns
- **Key Fields**: 
  - `Order Date`, `Days for shipping (real)`, `Days for shipment (scheduled)`
  - `Order Country`, `Customer Country`, `Order Region`
  - `Payment Type`, `Shipping Mode`
  - `Product Category`, `Product Name`
  - `Order Status`, `Late Delivery Risk`

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

####Business Questions

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
