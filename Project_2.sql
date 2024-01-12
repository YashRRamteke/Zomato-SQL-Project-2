 drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'2021-01-01'),
(2,'2021-01-03'),
(3,'2021-01-08'),
(4,'2021-01-15');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'2021-01-01 18:15:34','20km','32 minutes',''),
(2,1,'2021-01-01 19:10:54','20km','27 minutes',''),
(3,1,'2021-01-03 00:12:37','13.4km','20 mins','NaN'),
(4,2,'2021-01-04 13:53:03','23.4','40','NaN'),
(5,3,'2021-01-08 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'2021-01-08 21:30:45','25km','25mins',null),
(8,2,'2021-01-10 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'2021-01-11 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','2021-01-01 18:05:02'),
(2,101,1,'','','2021-01-01 19:00:52'),
(3,102,1,'','','2021-01-02 23:51:23'),
(3,102,2,'','NaN','2021-01-02 23:51:23'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,1,'4','','2021-01-04 13:23:46'),
(4,103,2,'4','','2021-01-04 13:23:46'),
(5,104,1,null,'1','2021-01-08 21:00:29'),
(6,101,2,null,null,'2021-01-08 21:03:13'),
(7,105,2,null,'1','2021-01-08 21:20:29'),
(8,102,1,null,null,'2021-01-09 23:54:33'),
(9,103,1,'4','1,5','2021-01-10 11:22:59'),
(10,104,1,null,null,'2021-01-11 18:34:49'),
(10,104,1,'2,6','1,4','2021-01-11 18:34:49');



A: ROLL METRICS
B: DRIVER AND CUSTOMER EXPERIENCE
C: INGREDIENT OPTIMISATION
D: PRICING AND RATINGS;


A: ROLL METRICS;

-- HOW MANY ROLLS WERE ORDERED
SELECT COUNT(roll_id) AS Total_orders
FROM customer_orders;

-- HOW MANY UNIQUE CUSTOMER ORDERS WERE MADE
SELECT COUNT(DISTINCT customer_id) AS Unique_cust
FROM customer_orders;

-- HOW MANY SUCCESFUL ORDERS WERE MADE BY EACH DRIVER
SELECT driver_id, COUNT(DISTINCT order_id) AS ORDERS
FROM driver_order
WHERE pickup_time NOT LIKE '%/NULL' 
GROUP BY driver_id;

-- HOW MANY OF EACH TYPE OF ROLL WAS DELIVERED
SELECT c.roll_id, COUNT(roll_id) as DELIVERED
FROM (
SELECT driver_order.order_id, customer_orders.roll_id 
FROM driver_order
JOIN customer_orders
ON  driver_order.order_id = customer_orders.order_id  AND driver_order.pickup_time NOT LIKE '%/NULL') c 
GROUP BY roll_id ;

-- HOW MANY VEG AND NON-VEG ROLLS WERE ORDERED BY EACH CUSTOMER
SELECT c.* , rolls.roll_name as Roll_name
FROM (SELECT customer_orders.customer_id, customer_orders.roll_id, COUNT(customer_orders.roll_id) as CNT
FROM customer_orders  
GROUP BY customer_id, roll_id ) c
JOIN rolls
ON c.roll_id = rolls.roll_id ;

-- WHAT IS THE MAXIMUM NUMBER OF ROLLS ORDERED IN A SINGLE ORDER
SELECT c.order_id, SUM(cnt)as num
FROM (SELECT customer_orders.order_id, customer_orders.roll_id, COUNT(roll_id) as cnt
FROM customer_orders
GROUP BY order_id, roll_id) c  
GROUP BY order_id 
ORDER BY num desc 
LIMIT 1;

-- For each customer, how many delivered orders had atleast one change and how many had no changes

-- CREATING A CLEAN TABLE 
WITH temp_customer_orders (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) 
AS 
(
 SELECT order_id,customer_id,roll_id,
 CASE WHEN not_include_items IS NULL OR not_include_items = '' then '0' else not_include_items end AS new_not_include_items,
 CASE WHEN extra_items_included IS NULL OR extra_items_included = '' OR extra_items_included = 'NaN' then '0' else extra_items_included end as new_extra_items_included,
 order_date
FROM customer_orders 
) ,
-- CREATING CLEAN TABLE
temp_driver_order (order_id,driver_id,pickup_time,distance,duration,cancellation)
AS 
(
SELECT order_id,driver_id,pickup_time,distance,duration,
CASE WHEN cancellation = 'Cancellation' OR cancellation = 'Customer Cancellation'  THEN '0' else 1  end as new_cancellation
FROM driver_order
)

SELECT customer_id, Changes, COUNT(order_id) as ORDER_
FROM(
SELECT * ,
CASE WHEN not_include_items = '0' and extra_items_included = '0' then 'No_change' else 'Change' end AS Changes
FROM temp_customer_orders 
WHERE order_id IN (
SELECT order_id
FROM temp_driver_order 
WHERE cancellation <> 0) )c -- can use !=
GROUP BY customer_id, Changes; 

-- HOW MANY ROLES WERE DELIVERED THAT HAD BOTH, EXCLUSIONS AND EXTRAS
-- CREATING A CLEAN TABLE 
WITH temp_customer_orders (order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) 
AS 
(
 SELECT order_id,customer_id,roll_id,
 CASE WHEN not_include_items IS NULL OR not_include_items = '' then '0' else not_include_items end AS new_not_include_items,
 CASE WHEN extra_items_included IS NULL OR extra_items_included = '' OR extra_items_included = 'NaN' then '0' else extra_items_included end as new_extra_items_included,
 order_date
FROM customer_orders 
) SELECT * FROM temp_customer_orders;

SELECT c.*, roll_id, not_include_items, extra_items_included
FROM (SELECT order_id
FROM driver_order
WHERE pickup_time NOT LIKE '%/NULL') c
JOIN customer_orders
ON c.order_id = customer_orders.order_id  
WHERE not_include_items != 0 AND extra_items_included != 0;

-- WHAT WAS THE TOTAL NUMBER OF ORDERS FOR EACH HOUR OF THE DAY
SELECT hr, COUNT(hr) as Orders
FROM (SELECT * , HOUR(order_date) AS hr
FROM customer_orders) c 
GROUP BY hr ;

-- WHAT WAS THE NUMBER OF ORDERS FOR EACH DAY OF THE WEEK
SELECT COUNT(order_id) AS Orders, DAYNAME(order_date) AS Days
FROM customer_orders
GROUP BY Days ;


select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

B: DRIVER AND CUSTOMER EXPERIENCE;

-- WHAT IS THE AVERAGE TIME IN MINUTES IT TOOK FOR EACH DRIVER TO REACH THE HEADQUARTERS TO PICK THE ORDER
SELECT e.driver_id, e.su/e.co as ave
FROM(
SELECT d.driver_id, SUM(d.timegap) AS su, COUNT(d.timegap) AS co
FROM (SELECT c.*, TIMEDIFF(c.pickup_time, c.order_date ) AS timegap
FROM(
SELECT customer_orders.order_id, customer_orders.order_date, driver_order.driver_id, driver_order.pickup_time
FROM customer_orders 
JOIN driver_order 
WHERE customer_orders.order_id = driver_order.order_id 
GROUP BY order_id, customer_orders.order_date, driver_order.pickup_time,driver_order.driver_id) c
WHERE pickup_time NOT LIKE '%/NULL') d 
GROUP BY driver_id) e ;

-- WHAT WAS THE AVERAGE DISTANCE TRAVELLED FOR EACH CUSTOMER
SELECT d.*, su/co as ave_dist
FROM (
SELECT c.customer_id, SUM(distance) as su, COUNT(distance) as co
FROM(
SELECT customer_orders.order_id, customer_orders.customer_id, driver_order.driver_id, driver_order.distance
FROM customer_orders 
JOIN driver_order 
WHERE customer_orders.order_id = driver_order.order_id AND distance NOT LIKE '%NULLwh' ) c
GROUP BY customer_id) d ;


