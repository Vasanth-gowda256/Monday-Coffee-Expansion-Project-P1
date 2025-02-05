--Monday coffe schemas
-- import tables

--1st impport table city
--2nd import table customers
--3rd import table products
--4th import table sales

-- add constraintrs to tables

--Add foreign key constraint to customers table

select top(1) * from city ;
select top(1) * from customers;


ALTER TABLE customers
ADD CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)

-- Add foreign keys to sales table

SELECT TOP(1)* FROM city;
SELECT TOP(1)* FROM customers;
SELECT TOP(1)* FROM products;
SELECT TOP(1)* FROM sales;

ALTER TABLE sales
ADD CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE sales
ADD CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

-- Monday Coffee --Data Analysis

SELECT TOP(5)* from city;
SELECT TOP(5)* from customers;
SELECT TOP(5)* from products;
SELECT TOP(5)* from sales;

--Reports and data analysis

-- Q.1 Coffee consumers count
-- How many people in  each city are estimated to consume coffee,given that 25% of the population does?

SELECT 
	city_name,
	population, 
	(population *0.25) AS '25% of population coffee consuming in millions',
	RANK() OVER (order by population desc) 
FROM city

--Q.2 Total Revenue from coffee sales
-- What is the total revenue generated from coffee sales across all the cities in the last quarter of 2023?

SELECT 
	SUM(total) AS total_sales
	FROM sales 
WHERE sale_date BETWEEN '2023-10-01' AND '2023-12-31'

--Q.3 Sales Count for each product
--How many unit of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.total) AS totals 
FROM products AS p

LEFT JOIN  sales AS s
	ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY 2 DESC

--Q.4 Average Sales amount per city
--What is the average sales amount per customer in each city?

SELECT 
	cy.city_name,
	SUM(s.total)AS total_sales_amount,
	COUNT(DISTINCT(s.customer_id)) AS count_of_customers,
	SUM(s.total)/COUNT(DISTINCT(s.customer_id)) AS average_sales_per_cust
FROM sales AS s

JOIN customers AS cu
	ON s.customer_id=cu.customer_id
JOIN city AS cy
	ON cu.city_id=cy.city_id
GROUP BY cy.city_name
ORDER BY average_sales_per_cust DESC

--Q.5 City population and coffee consumers(25%)
--Provide a list of cities along with their populations and estimated coffee consumers.
--return city name , total current customers , estimated coffee consumers (25%).


SELECT 
	city_name,
	population,
	(population*25)/100 AS estimated_coffee,
	COUNT(DISTINCT(s.customer_id))AS unique_customers
FROM city as cy

JOIN customers AS cu
	ON cy.city_id=cu.city_id
JOIN sales AS s
	ON s.customer_id=cu.customer_id
GROUP BY city_name,population
ORDER BY population DESC

--Q.6 Top selling products by city
-- what are the top 3 selling products in each city based on sales volume?


WITH product_sales AS
(
SELECT 
	DISTINCT(product_name),
	city_name,
	SUM(total) as total_sales_amount,
	COUNT(product_name) as total_orders,
	DENSE_RANK () OVER (PARTITION BY c.city_name ORDER BY SUM(total)DESC) AS Ranking
FROM products AS p
JOIN sales AS s
	ON p.product_id=s.product_id
JOIN customers AS cu
	ON s.customer_id=cu.customer_id
JOIN city AS c
	ON cu.city_id=c.city_id
GROUP BY product_name,city_name
) 
SELECT 
	product_name,
	city_name,total_sales_amount,
	total_orders,
	Ranking
FROM product_sales
WHERE Ranking <=3

--Q.7 customers segmentation by city
-- How many unique customers are there in each city who have purchased coffee product?

SELECT 
	city_name AS city,
	COUNT(DISTINCT(customer_name))AS unique_customers
FROM customers AS cu
JOIN city AS cy
	ON cu.city_id=cy.city_id
GROUP BY city_name

--Q 8 Average sales vs Rent
-- Find each city and their average sales per customer and avg rent per customer

SELECT TOP(1)* FROM city;
SELECT TOP(1)* FROM customers;
SELECT TOP(1)* FROM products;
SELECT TOP(1)* FROM sales;

WITH avgrent as
(
SELECT 
	cy.city_name,estimated_rent,
	COUNT(DISTINCT(s.customer_id))AS count_of_customers,
	SUM(s.total)/COUNT(DISTINCT(s.customer_id)) AS average_sales_per_customer
FROM sales as s

JOIN customers as cu
	ON s.customer_id=cu.customer_id
JOIN city as cy
	ON cu.city_id=cy.city_id
GROUP BY cy.city_name,estimated_rent
)
SELECT
	city_name,
	estimated_rent,
	count_of_customers,
	average_sales_per_customer ,
	(estimated_rent/count_of_customers) AS average_rent_per_customer
FROM avgrent
ORDER BY average_rent_per_customer DESC

--Q.9 Monthly sales growth
---Sales growth rate calculate the percentage growth (or decline) 
--in sales over different time periods (monthly) by each city.


SELECT TOP(1)* FROM city;
SELECT TOP(1)* FROM customers;
SELECT TOP(1)* FROM products;
SELECT TOP(1)* FROM sales;



WITH 
modified_years
AS (
SELECT 
	cy.city_name,
	SUM(total) AS total_sales,
	MONTH(sale_date) AS months,
	YEAR(sale_date) AS years
FROM city AS cy
JOIN customers AS cu
ON cy.city_id=cu.city_id
join sales AS s
ON cu.customer_id=s.customer_id
GROUP BY cy.city_name,MONTH(sale_date),YEAR(sale_date)
),
 monthly_analysis AS
(
SELECT 
	city_name,
	months,
	years, 
	total_sales,
	LAG(total_sales,1) OVER(PARTITION BY city_name ORDER BY city_name,years,months) AS comp_sales 
FROM modified_years

)
SELECT 
	city_name,
	months,
	years, 
	total_sales,
	comp_sales,
	(total_sales-comp_sales) AS growth_rate
	FROM monthly_analysis
	WHERE comp_sales is not null

--Q10 Market Potential Analysis
--Identify top 3  city based on highest sales ,return city name,total sales, total rent, 
--total customers and estimated coffe consumers
SELECT TOP(20)* FROM city;
SELECT TOP(1)* FROM customers;
SELECT TOP(1)* FROM products;
SELECT TOP(1)* FROM sales;


WITH totals as
(
SELECT
	city_name,
	SUM(total)AS total_sales,
	estimated_rent,
	ROUND((ci.population*0.25)/1000000,3) AS estimated_coffee_consumers_in_millions,
	COUNT(DISTINCT(cu.customer_id))AS total_customers
FROM city AS ci 
JOIN customers AS cu ON ci.city_id=cu.city_id
JOIN sales AS s ON s.customer_id=cu.customer_id
group by city_name,ci.population,estimated_rent
)
SELECT 
	city_name,
	total_sales,
	estimated_rent,
	estimated_coffee_consumers_in_millions,
	total_customers,
	(estimated_rent/total_customers) AS averge_rent,
	(total_sales/total_customers) AS sales_per_customer
FROM totals
GROUP BY city_name,total_sales,
	estimated_rent,
	estimated_coffee_consumers_in_millions,
	total_customers
ORDER BY total_sales DESC
/* 
--Recomondations
city 1: Pune
1. total sales is more compare to other cities
2.average rent per customer is low 
3.average sales per customer is high

city 2: Delhi
1.highest coffee consumers  which is 7.75 million
2.average sales per customer is also high
3.highest total customers is 68
4.average rent per customer is low as 330(still under 500)

city 3: Jaipur
1.highest customers is 69
2.total sales is also good compare to others
3.average rent per customer is very less which is 156

