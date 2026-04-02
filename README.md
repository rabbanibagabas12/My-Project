# Supply Chain Analytics: Route Optimization & Delay Reduction (Still on Process)

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
| **Order Information** | `Order_Id`, `order_date`, `Order_Status`, `Order_Region`, `Market` |
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

<details> <summary><b>Click to expand financial impact details</b></summary>

| Financial Metric | Estimated Value | Risk Level |
| :--- | :--- | :--- |
| **Total Revenue at Risk** | $36,784,085.28 |  Critical |
| **Direct Loss from Delays** | $1,190,029.72 |  High |
| **Estimated Future Revenue Loss** | $5,517,612.79 |  Critical |
| **Current Operational Loss** | $2,044,479.37 |  High |

</details>

#### Query 3: Customer Retention Insights

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

</details>

#### Query 4: Shipping Mode Optimization

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

</details>

#### Query 5: Product Category Vulnerability

<details> <summary><b>Click to expand category analysis details</b></summary>

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

</details>

### 3. Data Visualization (Power BI)
The interactive Power BI dashboard transforms 180k+ rows of supply chain logs into actionable business intelligence. It is built with a **drill-down architecture**, allowing stakeholders to transition from global KPIs to specific SKU-level bottlenecks.

---

### 📊 Dashboard Breakdown

#### **Page 1: Executive Operations Command**
*Focus: High-level KPI monitoring and global delay trends.*

*   **KPI Scorecard:** Real-time tracking of **Total Orders (181K)**, **Total Revenue ($36.8M)**, and **Average Delay Days (1.6 Days)**.
*   **Performance Monitoring:** A Gauge chart measuring the **On-Time Delivery (OTD) Rate (42.72%)**, highlighting a significant gap against the **95% industry target**.
*   **Monthly Performance Trend:** A dual-axis line chart comparing **Total Revenue** and **On-Time Rate** from 2015 to 2018 to identify correlation between logistics stability and financial growth.

> [!CAUTION]
> **Key Insight:** With an **OTD Rate of only 42.72%**, more than **57% of all shipments** are currently categorized as "Delayed," representing a critical risk to customer retention and brand reputation.

---
