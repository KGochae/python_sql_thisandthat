# 클래식 리텐션
# 고객의 첫 번째 주문
With TABLE1 as (
	SELECT Customer_ID
		, min(Order_date) as first_order_date    
	FROM us
	GROUP BY Customer_ID),


# 기존의 모든 고객 구매 데이터에, 고객 첫주문 정보를 JOIN 해줍니다. 
TABLE2 AS(
select A.Customer_ID
    , A.Order_date
    , date_format(A.Order_date, '%Y-%m-01') AS order_month
    , B.first_order_date
    , date_format(B.first_order_date, '%Y-%m-01') AS first_order_month
from US AS A
LEFT JOIN TABLE1 AS B ON A.Customer_ID = B.Customer_ID )



SELECT first_order_month
	, count(distinct Customer_ID) AS month0
	, ROUND(count(distinct CASE WHEN DATE_ADD(first_order_month, INTERVAL 1 month) = order_month THEN Customer_ID END)/count(distinct Customer_ID),2)*100  month1  
  	, ROUND(count(distinct CASE WHEN DATE_ADD(first_order_month, INTERVAL 2 month) = order_month THEN Customer_ID END)/count(distinct Customer_ID),2)*100 month2  
  	, ROUND(count(distinct CASE WHEN DATE_ADD(first_order_month, INTERVAL 3 month) = order_month THEN Customer_ID END)/count(distinct Customer_ID),2)*100 month3  
  	, ROUND(count(distinct CASE WHEN DATE_ADD(first_order_month, INTERVAL 4 month) = order_month THEN Customer_ID END)/count(distinct Customer_ID),2)*100 month4 
  	, ROUND(count(distinct CASE WHEN DATE_ADD(first_order_month, INTERVAL 5 month) = order_month THEN Customer_ID END)/count(distinct Customer_ID),2)*100 month5  
  	, ROUND(count(distinct CASE WHEN DATE_ADD(first_order_month, INTERVAL 6 month) = order_month THEN Customer_ID END)/count(distinct Customer_ID),2)*100 month6  
    
FROM TABLE2
GROUP BY first_order_month
