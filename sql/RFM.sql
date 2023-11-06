WITH Customer AS  (
				SELECT Customer_ID
						, segment
						, DATE(MIN(order_date)) AS first_order_date  
						, DATE(MAX(order_date)) AS last_order_date
						, COUNT(DISTINCT order_id) AS cnt_orders
						, ROUND(SUM(Sales),2) AS sum_sales
				FROM us
				GROUP BY Customer_ID
)


, Customer_stats AS (SELECT  Customer_ID
							,last_order_date
							,cnt_orders
							,sum_sales
							,DATEDIFF('2020-12-31',last_order_date) AS days
					FROM Customer
                    )

# RFM 점수
-- SELECT recency
-- 	,frequency
--     ,monetary
--     ,COUNT(Customer_ID) AS cnt_customer
-- FROM Customer_stats
-- GROUP BY recency, frequency, monetary


# EDA 

################################## 카테고리별 판매 비중 ##################################

, pct AS (SELECT *
    , SUM(sub_cnt_orders) OVER (PARTITION BY category) AS category_cnt_orders
	, ROUND(SUM(sub_category_sales) OVER (PARTITION BY category),2) AS category_sales
    , SUM(sub_category_sales) OVER () AS total_sales
    , ROUND(sub_category_sales/SUM(sub_category_sales) OVER (PARTITION BY category),2) as categoy_pct
    , ROUND(sub_category_sales / SUM(sub_category_sales) OVER (),3) as total_pct
FROM (SELECT Category
			, Sub_category
			, COUNT(*) AS sub_cnt_orders
			, ROUND(SUM(Sales),2) AS sub_category_sales
		FROM US
		GROUP BY Category, Sub_Category) A
   )     
##################### 고객별 매출 ########################### 
, seg as (
SELECT segment
	, cnt_segment
    , sum_sales
    , SUM(cnt_segment) OVER() as total_cnt
    , SUM(sum_sales) OVER() as total_sales
    , ROUND(sum_sales/SUM(sum_sales) OVER(),2) as sales_pct
    , ROUND(cnt_segment/SUM(cnt_segment) OVER() ,2)as cnt_pct

FROM (SELECT Segment
			,count(*) as cnt_segment
			,ROUND(SUM(sales),2) as sum_sales
		FROM US
		GROUP BY Segment) A
)        


############ RFM 점수 기준을 구해보자 ############
# R
, R AS 	(SELECT *
			,  ROUND(PERCENT_RANK() OVER (ORDER BY  days ), 2) as percentile
		FROM(SELECT Customer_ID
					,DATEDIFF('2020-12-31',last_order_date) AS days
			FROM customer ) A
		)
# F
, F AS ( SELECT Customer_id
				, cnt_orders
				, ROUND(percent_rank() OVER (ORDER BY cnt_orders desc),2) as percentile
			FROM  customer
			ORDER BY CNT_ORDERS)

# m
, m as  (SELECT customer_id
		, sum_sales
		, ROUND(percent_rank() OVER (ORDER BY sum_sales DESC ),2) as percentile
	FROM customer)



################### RFM #####################

,RFM_states as (
				SELECT *
					, COUNT(customer_id) as cnt
				FROM (SELECT *
							,CASE WHEN days <= 50 THEN 1
								ELSE 0 END AS recency
							,CASE WHEN cnt_orders >= 3 THEN 1 
								ELSE 0 END AS frequency
							,CASE WHEN sum_sales >= 1395 THEN 1 
								ELSE 0 END AS monetary 
						FROM Customer_stats) a
				GROUP BY recency, frequency, monetary)

,RFM AS (SELECT *
			,CASE WHEN days <= 50 THEN 1
				ELSE 0 END AS recency
			,CASE WHEN cnt_orders >= 3 THEN 1 
				ELSE 0 END AS frequency
			,CASE WHEN sum_sales >= 1395 THEN 1 
				ELSE 0 END AS monetary 
		FROM Customer_stats)

####################### 각 고객별 등급 매기기 ########################################


,RFM_SEG AS( SELECT Customer_ID
					, SEGMENT
				FROM (SELECT *
							,CASE WHEN recency = 1 and frequency = 1 and monetary = 1 THEN 'vip'
								WHEN recency = 1 and frequency = 1 and monetary = 0 THEN 'poten_vip1'
								WHEN recency = 1 and frequency = 0 and monetary = 1 THEN 'poten_vip2'
								WHEN recency = 0 and frequency = 1 and monetary = 1 THEN 'left_vip'
								WHEN recency = 1 and frequency = 0 and monetary = 0 THEN 'new_user'
								WHEN recency = 0 and frequency = 0 and monetary = 0 THEN 'left_user'
								ELSE 'else' END AS SEGMENT
						FROM RFM) A
        )
################# vip 등급은 어떤 제품을 주로 구매 했을까 ? ############################

, customer_seg as(
					SELECT a.*
							,b.SEGMENT as seg
					FROM US a
						LEFT JOIN RFM_SEG b ON a.Customer_ID = b.Customer_ID 
					)



# vip(잠재력 vip 포함)의 카테고리 별 pct                    
SELECT *
    , SUM(sub_cnt_orders) OVER (PARTITION BY category) AS category_cnt_orders
	, ROUND(SUM(sub_category_sales) OVER (PARTITION BY category),2) AS category_sales
    , ROUND(SUM(sub_category_sales) OVER (),2) AS total_sales
    , ROUND(sub_category_sales/SUM(sub_category_sales) OVER (PARTITION BY category),2) as category_pct
    , ROUND(sub_category_sales / SUM(sub_category_sales) OVER (),3) as total_pct
FROM(SELECT Category
			, Sub_category
			, COUNT(*) AS sub_cnt_orders
			, ROUND(SUM(Sales),2) AS sub_category_sales
		FROM customer_seg
        WHERE seg in ('vip','poten_vip1','poten_vip2')
		GROUP BY Category, Sub_Category) A
