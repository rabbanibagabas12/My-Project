# Supply Chain Analytics: Shipping Route Optimization & Delay Analysis

## Project Overview
This data analytics project analyzes the DataCo Supply Chain dataset to identify the slowest shipping routes and uncover root causes of delivery delays. By examining shipping performance across different routes, carriers, and product categories, this project provides actionable recommendations for route optimization and vendor selection to improve on-time delivery rates.

**Business Value:** Reduce shipping delays by 20-30% through data-driven route and vendor optimization strategies.

## Business Questions
1. **Which shipping routes experience the longest delivery times?**
   - Identify top 10 slowest origin-destination pairs
   - Compare planned vs actual delivery times

2. **What are the primary factors causing shipping delays?**
   - Carrier performance analysis
   - Product category impact
   - Geographic patterns
   - Seasonal trends

3. **Which vendors/carriers have the best on-time delivery records?**
   - Vendor reliability scoring
   - Consistency analysis across routes

4. **What alternative routes or vendors can improve delivery efficiency?**
   - Route substitution recommendations
   - Carrier selection framework

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
- Total records: [X] rows
- Missing values identified and handled:
  - `Delivery Date`: [X] nulls removed
- Data types verified and corrected
- Calculated new columns:
  - `Delay Days` = Actual Delivery Days - Planned Delivery Days

**Data Quality Summary:**
