CREATE DATABASE GLOBAL_EV_SALES;
-- ELECTRIC VEHICLE

USE GLOBAL_EV_SALES;

SELECT * FROM global_ev_sales.`iea global ev data 2024`;
/* 1. Battery Electric Vehicles (BEVs)are fully electric vehicles powered entirely by batteries. EX: Tesla Model 3, Nissan Leaf.
2. Fuel Cell Electric Vehicles (FCEVs)are electric vehicles that generate electricity on board using a fuel cell, typically powered by hydrogen. 
The hydrogen fuel is combined with oxygen from the air in the fuel cell to produce electricity, which then powers the electric motor. 
EX: Toyota Mirai, Hyundai Nexo.
3. Plug-in Hybrid Electric Vehicles (PHEVs)are a type of hybrid vehicle that combines the benefits of both electric and traditional internal 
combustion engines (ICEs). INTERNAL COMBATION ENGINER are having backup of a gasoline or diesel engine for longer trips. EX: Ford Escape Plug-In Hybrid,
Toyota Prius Prime. */

-- Checking which regions data set is provided ?
select distinct region from global_ev_sales.`iea global ev data 2024`;

-- Finding which year has the highest values ( prediction till 2035) ?
select year, value from global_ev_sales.`iea global ev data 2024` order by value desc limit 3;

-- Calculating the highest value grouping by year ?
select year,max(value) from global_ev_sales.`iea global ev data 2024`group by year;

-- Claculating the % of category under power train column ?
SELECT powertrain,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS powertrain_usage_percentage
FROM global_ev_sales.`iea global ev data 2024`  GROUP BY powertrain;

-- Finding out how much value is generated from India for Electric vehicle?
select round(sum(value), 2) as rounded_sum_value from global_ev_sales.`iea global ev data 2024` where region = 'india';

-- Checking what are different methods of charging Electric Vehile ?
select distinct unit from global_ev_sales.`iea global ev data 2024`;
/* percent (measures the charging out of 100), vehicles(charges as per the count of vehicles), charging( measure the unit charged),
GWH(measure large amount of electric comsumption), MBPD (used in oil industry for consumption of crude oil), OD(measure the oil
consumption been reduced) */

--  How can you calculate the 3-year rolling average of EV sales for each region using a window function?
SELECT region, year, AVG(value) OVER (PARTITION BY region ORDER BY year desc ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_avg_ev_sales
FROM global_ev_sales.`iea global ev data 2024` WHERE parameter = 'EV sales';

-- Using CTE to find out the year-on-year percentage growth in EV stock for each region?
WITH EV_stock_growth AS (SELECT region, year,parameter,  value AS ev_stock,LAG(value)OVER (PARTITION BY region ORDER BY year) 
AS prev_year_stock FROM global_ev_sales.`iea global ev data 2024` WHERE parameter = 'EV stock'
)
SELECT region, year, parameter, (ev_stock - prev_year_stock) / prev_year_stock * 100 AS YOY_growth
FROM EV_stock_growth WHERE prev_year_stock ;

-- Calculating sum of value using window function?
select region, year, unit,value,round(sum(value) over(order by year),2) as sum_of_value 
from global_ev_sales.`iea global ev data 2024`;

-- Calculating the future value using window function?
select region, parameter, year, value, lead(value) over(partition by parameter order by year) as calculating_future_value
from global_ev_sales.`iea global ev data 2024`;

-- Using rank () and givivng rank to values based on region and year ? 
SELECT region, year, value AS ev_sales_share,RANK() OVER (PARTITION BY region ORDER BY value DESC) AS rank_by_sales_share
FROM global_ev_sales.`iea global ev data 2024` WHERE parameter = 'EV sales share';

-- Using row num () and creating a tempoaray row_num column ?
select row_number() over(partition by region order by year) as row_num , region,parameter, year 
from global_ev_sales.`iea global ev data 2024`;

-- Creating a finction for powertrain column which has many category ? 
select distinct powertrain from global_ev_sales.`iea global ev data 2024`;

delimiter $$
create function vehicles_availability_status(powertrain varchar(60))
returns varchar(60)
deterministic
begin
declare vehicles_availability_status varchar (60);
if powertrain = 'EV' then
   set vehicles_availability_status = 'Quick delivery';
elseif powertrain = 'BEV' then
   set vehicles_availability_status = 'Deliver after 1 week of order';
elseif powertrain = 'PHEV' then
   set vehicles_availability_status = 'Deliver after 1 month of order';
elseif powertrain = 'Publicly_available_fast' then
   set vehicles_availability_status = 'Customer Satisfied';
elseif powertrain = 'Publicly_available_slow' then
   set vehicles_availability_status = 'Customer Dissatisfied'; 
elseif powertrain = 'FCEV' then
   set vehicles_availability_status = 'Deliver after 2 month of order';
else
  set vehicles_availability_status = 'Pending';
end if;
return vehicles_availability_status;
end $$

select vehicles_availability_status('wcv');

-- Creating a self join with in the table to compare the EV stock and EV sales parameters within the same region and year.
SELECT 
a.region AS region_a, a.year AS year_a, a.category AS category_a,a.parameter AS parameter_a, a.value AS value_a,
b.region AS region_b,b.year AS year_b,b.category AS category_b,b.parameter AS parameter_b,b.value AS value_b
FROM 
    global_ev_sales.`iea global ev data 2024` a
JOIN 
    global_ev_sales.`iea global ev data 2024` b
ON 
    a.region = b.region AND a.year = b.year
WHERE 
    a.parameter = 'EV stock' AND b.parameter = 'EV sales';

-- Creating a stored procedure for mode column and finding the sum of values based on its category ?
DELIMITER //
CREATE PROCEDURE Getmode()
BEGIN
    select mode,sum(value) from global_ev_sales.`iea global ev data 2024` group by mode;
end //  
  
DELIMITER ;

CALL getmode();

-- Creation of views
create view EV_sales_view as select * from global_ev_sales.`iea global ev data 2024`;
select * from EV_sales_view;