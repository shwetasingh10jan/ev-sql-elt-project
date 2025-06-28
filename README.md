1.Top 5 States by Total EV Sales

SELECT ds.state_name, SUM(f.ev_sales_quantity) AS total_sales
FROM fact_ev_sales f
JOIN dim_state ds ON f.state_id = ds.state_id
GROUP BY ds.state_name
ORDER BY total_sales DESC
LIMIT 5; 

2.Charging Stations by State

SELECT ds.state_name, COUNT(*) AS station_count
FROM fact_charging_stations f
JOIN dim_state ds ON f.state_id = ds.state_id
GROUP BY ds.state_name
ORDER BY station_count DESC
LIMIT 5;

3.EV Sales Category Summary

SELECT sales_category, COUNT(*) AS total_records
FROM fact_ev_sales
GROUP BY sales_category;

