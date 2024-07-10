/* 1- Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region. */

Select distinct market 
from dim_customer 
where customer = 'Atliq Exclusive' and region = 'APAC';

/* 2- What is the percentage of unique product increase in 2021 vs. 2020? */

    with t1 as
	(select count(distinct product_code) as 'unique_products_2020'
    from fact_sales_monthly
	where fiscal_year = 2020),
t2 as
	(select count(distinct product_code) as 'unique_products_2021' 
    from fact_sales_monthly
	where fiscal_year = 2021)
select unique_products_2020,
	   unique_products_2021,
       Round( 100 *(unique_products_2021-unique_products_2020) /unique_products_2020,2) as Percentage_increase from t1,t2;

/* 3- Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts */ 

select segment, count(distinct product_code) as unique_products_count
from dim_product
group by segment
order by unique_products_count desc;
      
/* 4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020 */    

with t1 as
	(select segment,count( distinct product_code) as 'product_count_2020'
	from fact_sales_monthly join dim_product using(product_code)
	where fiscal_year = 2020
	group by 1
	order by 2 desc),
t2 as
	(select segment,
			count( distinct product_code) as 'product_count_2021'
	from fact_sales_monthly 
						join dim_product using(product_code)
	where fiscal_year = 2021
	group by 1
	order by 2 desc)
select t1.segment,
	   product_count_2020 , 
       product_count_2021 ,
	   product_count_2021 -product_count_2020 as difference from t1 
join t2 using (segment)
order by 4 desc;

/* Get the products that have the highest and
lowest manufacturing costs. The final output should contain these
fields, product_code product manufacturing_cost */

SELECT p.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost AS m INNER JOIN dim_product AS p
ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
UNION
SELECT p.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost AS m INNer join dim_product AS p
ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

/* 6 Generate a report which contains the 
top 5 customers who received an average high 
pre_invoice_discount_pct for the fiscal year 
2021 and in the Indian market. The final output 
contains these fields, customer_code customer 
average_discount_percen */

select c.customer, c.customer_code,  p.pre_invoice_discount_pct
from dim_customer as c 
JOIN fact_pre_invoice_deductions AS p ON c.customer_code = p.customer_code
WHERE p.pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions) AND c.market='India' AND p.fiscal_year = 2021
ORDER BY p.pre_invoice_discount_pct DESC
LIMIT 5;

/* 7- Get the complete report of
the Gross sales amount for the customer
 “Atliq Exclusive” for each month . This analysis helps to get 
 an idea of low and high-performing months and take strategic 
 decisions. The final report contains these columns: Month Year 
 Gross sales Amount*/
 
 Select MONTH(s.date) as Month,
 Year(s.date) as Year,
 SUM(Round((s.sold_quantity*g,gross_price),2)) as gross_sales_amount
from fact_sales_monthly as s 
JOIN dim_customer as c on s.customer_code = c.customer_code
Join fact_gross_price g on s.product_code = g.product_code
where c.customer_code = 'atliq exclusive'
group by month,year 
Order by year;

/* 8- In which quarter of 2020,
got the maximum total_sold_quantity?
The final output contains these fields sorted
by the total_sold_quantity, Quarter total_sold_quantity */

SELECT
CASE
	WHEN MONTH(date) IN (9, 10, 11) THEN 'Qtr 1'
    WHEN MONTH(date) IN (12, 1, 2) THEN 'Qtr 2'
    WHEN MONTH(date) IN (3, 4, 5) THEN 'Qtr 3'
    WHEN MONTH(date) IN (6, 7, 8) THEN 'Qtr 4'
    END AS Quarter,
SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC; 

/* 9- Which channel helped to bring more
 gross sales in the fiscal year 2021 and
 the percentage of contribution? The final
 output contains these fields, channel gross_sales_mln percentage */

WITH gross_sales_cte AS 
( 
  SELECT c.channel,
	ROUND(SUM((s.sold_quantity * g.gross_price)/1000000),2) AS gross_sales_mln
	FROM fact_sales_monthly AS s
	INNER JOIN fact_gross_price AS g
	ON  s.product_code = g.product_code
	INNER JOIN dim_customer AS c
	ON s.customer_code = c.customer_code
	WHERE s.fiscal_year = 2021
	GROUP BY c.channel
	ORDER BY gross_sales_mln DESC
    )
    SELECT *, gross_sales_mln*100/SUM(gross_sales_mln) OVER() AS percent
FROM gross_sales_cte;

/* 10 - Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields, division product_code,
product, total_sold_quantity rank_order*/

With division_sales_cte as 
( select p.division, s.product_code, p.product, SUM(s.sold_quantity) as total_sold_quantity,
 row_number() OVER (PARTITION BY p.division ORDER BY sum(s.sold_quantity) DESC) AS rank_order
 from fact_sales_monthly as s 
 JOIN dim_product p on s.product_code = p.product_code 
 where s.fiscal_year = 2021 
 GROUP BY p.division, s.product_code, p.product
 )
 select division, product_code, product, total_sold_quantity, rank_order
 FROM division_sales_cte
 WHERE rank_order <= 3;
