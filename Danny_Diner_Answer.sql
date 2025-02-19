--What is the total amount each customer spent at the restaurant?
select customer_id,sum(menu.price) as total_amount
from sales
join menu 
on sales.product_id=menu.product_id
group by 1

--How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as visited_days
from sales
group by 1

--What was the first item from the menu purchased by each customer? 
with date_cte as (
select 
mem.customer_id,m.product_name,s.order_date,
dense_rank() over (partition by mem.customer_id order by s.order_date asc) as rank_date
from members mem
join sales s
on mem.customer_id=s.customer_id
join menu m
on m.product_id=s.product_id
group by 1,2,3)
select 
customer_id,product_name
from date_cte
where rank_date =1
group by 1,2

--What is the most purchased item on the menu and how many times was it purchased by all customers?
select 
m.product_name,count(s.product_id) as most_purchased
from sales s
join menu m
on s.product_id=m.product_id
group by 1
order by 2 desc
limit 1

--Which item was the most popular for each customer?
with base as (
select 
mem.customer_id,m.product_name,count(s.product_id) as purchased,
rank() over (partition by mem.customer_id order by count(s.product_id) desc) as rank_pur
from sales s
join menu m
on s.product_id=m.product_id
join members mem
on mem.customer_id=s.customer_id
group by 1,2
) 
select 
distinct customer_id,product_name,purchased
from base
where rank_pur =1
group by 1,2,3

--Which item was purchased first by the customer after they became a member?
with taste as (
select 
mem.customer_id,m.product_name,order_date,
rank() over (partition by mem.customer_id order by order_date asc) as rank_date
from sales s
join menu m
on s.product_id=m.product_id
join members mem
on mem.customer_id=s.customer_id
group by 1,2,3
) 
select 
distinct customer_id,product_name
from taste
where rank_date =1
group by 1,2

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
mem.customer_id,
sum(case when m.product_name LIKE '%sushi%' then m.price*20 else m.price*10 end) as point
from members mem
join sales s
on mem.customer_id=s.customer_id
join menu m
on m.product_id=s.product_id
group by 1

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select 
mem.customer_id,
sum(case when s.order_date<=date_add(mem.join_date, INTERVAL 6 DAY) then m.price*20 else
case when m.product_name LIKE '%sushi%' then m.price*20 else m.price*10 end
end) as Jan_point
from members mem
join sales s
on mem.customer_id=s.customer_id
join menu m
on m.product_id=s.product_id
where date_trunc(s.order_date,MONTH)='2021-01-01'
AND mem.customer_id IN ('A', 'B')
group by 1
