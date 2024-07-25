-- SQL QUERY WITH FLO DATASET

--QUESTION 1: Create a table named FLO in a database named Customers that includes the variables given in the dataset.

CREATE DATABASE CUSTOMERS

CREATE TABLE FLO (
	master_id				VARCHAR(50),
	order_channel				VARCHAR(50),
	last_order_channel			VARCHAR(50),
	first_order_date			DATE,
	last_order_date				DATE,
	last_order_date_online			DATE,
	last_order_date_offline			DATE,
	order_num_total_ever_online		INT,
	order_num_total_ever_offline		INT,
	customer_value_total_ever_offline	FLOAT,
	customer_value_total_ever_online	FLOAT,
	interested_in_categories_12		VARCHAR(50),
	store_type				VARCHAR(10)
);


--QUESTION 2: Write a query to show the number of different customers who have made purchases.

SELECT COUNT(DISTINCT(master_id)) AS DISTINCT_CUSTOMER_COUNT FROM FLO;


--QUESTION 3: Write a query to retrieve the total number of purchases and the total revenue.

SELECT 
    SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_PURCHASE_COUNT,
    ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOTAL_REVENUE
FROM FLO;


--QUESTION 4: Write a query to retrieve the average revenue per purchase.

SELECT  
    ROUND((SUM(customer_value_total_ever_offline + customer_value_total_ever_online) / 
    SUM(order_num_total_ever_online + order_num_total_ever_offline)), 2) AS AVERAGE_REVENUE_PER_PURCHASE
FROM FLO;



--QUESTION 5:Write a query to retrieve the total revenue and the number of purchases made through the last order channel (last_order_channel).

SELECT  
    last_order_channel AS LAST_ORDER_CHANNEL,
    SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS TOTAL_REVENUE,
    SUM(order_num_total_ever_online + order_num_total_ever_offline) AS TOTAL_PURCHASE_COUNT
FROM FLO
GROUP BY last_order_channel;


--QUESTION 6: Write a query to retrieve the total revenue obtained, broken down by store type.

SELECT 
    store_type AS STORE_TYPE, 
    ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOTAL_REVENUE
FROM FLO 
GROUP BY store_type;


--BONUS: The parsed version of the data within the store type.

SELECT Value, SUM(TOTAL_REVENUE/COUNT_) 
FROM
(SELECT store_type AS STORE_TYPE,
(SELECT COUNT(VALUE) FROM string_split(store_type, ',')) AS COUNT_,
ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOTAL_REVENUE
FROM FLO 
GROUP BY store_type
) T
CROSS APPLY (SELECT VALUE FROM string_split(T.STORE_TYPE, ',')) D
GROUP BY Value;

 

--QUESTION 7: Write a query to retrieve the number of purchases broken down by year (base the year on the customer's first order date, first_order_date).

SELECT 
    YEAR(first_order_date) AS YEAR,  
    SUM(order_num_total_ever_offline + order_num_total_ever_online) AS PURCHASE_COUNT
FROM FLO
GROUP BY YEAR(first_order_date);



--QUESTION 8: Write a query to calculate the average revenue per purchase broken down by the last order channel (last_order_channel).

SELECT 
    last_order_channel, 
    ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online), 2) AS TOTAL_REVENUE,
    SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_PURCHASE_COUNT,
    ROUND(SUM(customer_value_total_ever_offline + customer_value_total_ever_online) / 
          SUM(order_num_total_ever_offline + order_num_total_ever_online), 2) AS REVENUE_PER_PURCHASE
FROM FLO
GROUP BY last_order_channel;



--QUESTION 9: Write a query to retrieve the most popular category in the last 12 months.

SELECT 
    interested_in_categories_12, 
    COUNT(*) AS FREQUENCY 
FROM FLO
GROUP BY interested_in_categories_12
ORDER BY FREQUENCY DESC;


--BONUS - > The parsed solution for the categories.

SELECT K.VALUE, SUM(T.FREQUENCY / T.COUNT) 
FROM 
(
    SELECT 
        (SELECT COUNT(VALUE) FROM string_split(interested_in_categories_12, ',')) AS COUNT,
        REPLACE(REPLACE(interested_in_categories_12, ']', ''), '[', '') AS CATEGORY, 
        COUNT(*) AS FREQUENCY 
    FROM FLO
    GROUP BY interested_in_categories_12
) T 
CROSS APPLY (SELECT * FROM string_split(T.CATEGORY, ',')) K
GROUP BY K.VALUE;



--QUESTION 10: Write a query to retrieve the most preferred store_type.

SELECT TOP 1   
    store_type, 
    COUNT(*) AS FREQUENCY 
FROM FLO 
GROUP BY store_type 
ORDER BY FREQUENCY DESC;


--BONUS - > The solution using ROWNUMBER.

SELECT * FROM
(
    SELECT    
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS ROWNR,
        store_type, 
        COUNT(*) AS FREQUENCY 
    FROM FLO 
    GROUP BY store_type 
) T 
WHERE ROWNR = 1;



--QUESTION 11: Write a query to retrieve the most popular category and the total amount of purchases made in that category, based on the last order channel (last_order_channel).

SELECT DISTINCT 
    last_order_channel,
    (
        SELECT TOP 1 interested_in_categories_12
        FROM FLO  
        WHERE last_order_channel = f.last_order_channel
        GROUP BY interested_in_categories_12
        ORDER BY SUM(order_num_total_ever_online + order_num_total_ever_offline) DESC
    ) AS MOST_POPULAR_CATEGORY,
    (
        SELECT TOP 1 SUM(order_num_total_ever_online + order_num_total_ever_offline)
        FROM FLO  
        WHERE last_order_channel = f.last_order_channel
        GROUP BY interested_in_categories_12
        ORDER BY SUM(order_num_total_ever_online + order_num_total_ever_offline) DESC
    ) AS TOTAL_PURCHASE_AMOUNT
FROM FLO F;


--BONUS - > The solution using the CROSS APPLY method.

SELECT DISTINCT 
    last_order_channel,
    D.interested_in_categories_12,
    D.TOTAL_PURCHASE_AMOUNT
FROM FLO F
CROSS APPLY 
(
    SELECT TOP 1 
        interested_in_categories_12,
        SUM(order_num_total_ever_online + order_num_total_ever_offline) AS TOTAL_PURCHASE_AMOUNT
    FROM FLO   
    WHERE last_order_channel = f.last_order_channel
    GROUP BY interested_in_categories_12
    ORDER BY SUM(order_num_total_ever_online + order_num_total_ever_offline) DESC
) D;


--QUESTION 12: Write a query to retrieve the ID of the person who made the most purchases.

SELECT TOP 1 master_id   
FROM FLO 
GROUP BY master_id 
ORDER BY SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC;


--BONUS

SELECT D.master_id
FROM 
    (SELECT master_id, 
            ROW_NUMBER() OVER (ORDER BY SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC) AS RN
     FROM FLO 
     GROUP BY master_id) AS D
WHERE RN = 1;



--QUESTION 13: Write a query to retrieve the average revenue per purchase and the average number of days between purchases (purchase frequency) for the person who made the most purchases.

SELECT 
    D.master_id,
    ROUND((D.TOTAL_REVENUE / D.TOTAL_PURCHASE_COUNT), 2) AS AVERAGE_REVENUE_PER_PURCHASE,
    ROUND((DATEDIFF(DAY, first_order_date, last_order_date) / D.TOTAL_PURCHASE_COUNT), 1) AS AVERAGE_DAYS_BETWEEN_PURCHASES
FROM
(
    SELECT TOP 1 
        master_id, 
        first_order_date, 
        last_order_date,
        SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS TOTAL_REVENUE,
        SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_PURCHASE_COUNT
    FROM FLO 
    GROUP BY master_id, first_order_date, last_order_date
    ORDER BY TOTAL_REVENUE DESC
) D;


-- QUESTION 14: Write a query to retrieve the average number of days between purchases (purchase frequency) for the top 100 people with the highest total revenue.SELECT  

SELECT  
    D.master_id,
    D.TOTAL_REVENUE,
    D.TOTAL_PURCHASE_COUNT,
    ROUND((D.TOTAL_REVENUE / D.TOTAL_PURCHASE_COUNT), 2) AS AVERAGE_REVENUE_PER_PURCHASE,
    DATEDIFF(DAY, first_order_date, last_order_date) AS TOTAL_DAYS_BETWEEN_PURCHASES,
    ROUND((DATEDIFF(DAY, first_order_date, last_order_date) / D.TOTAL_PURCHASE_COUNT), 1) AS AVERAGE_DAYS_BETWEEN_PURCHASES
FROM
(
    SELECT TOP 100 
        master_id, 
        first_order_date, 
        last_order_date,
        SUM(customer_value_total_ever_offline + customer_value_total_ever_online) AS TOTAL_REVENUE,
        SUM(order_num_total_ever_offline + order_num_total_ever_online) AS TOTAL_PURCHASE_COUNT
    FROM FLO 
    GROUP BY master_id, first_order_date, last_order_date
    ORDER BY TOTAL_REVENUE DESC
) D;


--QUESTION 15: Write a query to retrieve the most frequent customer in the last order channel (last_order_channel).

SELECT DISTINCT 
    last_order_channel,
    (
        SELECT TOP 1 master_id
        FROM FLO  
        WHERE last_order_channel = f.last_order_channel
        GROUP BY master_id
        ORDER BY SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC
    ) AS MOST_FREQUENT_CUSTOMER,
    (
        SELECT TOP 1 SUM(customer_value_total_ever_offline + customer_value_total_ever_online)
        FROM FLO  
        WHERE last_order_channel = f.last_order_channel
        GROUP BY master_id
        ORDER BY SUM(customer_value_total_ever_offline + customer_value_total_ever_online) DESC
    ) AS REVENUE
FROM FLO F;



--QUESTION 16: Write a query to retrieve the ID of the person who made the most recent purchase. (In case of multiple purchases on the most recent date, include all IDs.)

SELECT 
    master_id,last_order_date 
FROM FLO
WHERE last_order_date = (SELECT MAX(last_order_date) FROM FLO);


