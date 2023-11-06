-- -------- <인구수> 행정동 법정동 매핑 코드 -----------

WITH DF AS (SELECT B.*
					,A.인구수 AS 행정동인구수
			FROM 행정동인구밀도 A
				LEFT JOIN 행정법정 B ON A.﻿자치구 = B.﻿시군구
									AND A.행정동 = B.행정구역명)

---------- <인구수> 법정동 1 : N 행정동 ---------

, DF2 AS ( SELECT *
				,COUNT(B_CODE) AS SAME_Bcnt
				,SUM(행정동인구수) AS 법정동인구수CASE1
			FROM DF
			GROUP BY B_CODE) 
            
---------- <인구수> 행정동 1 : N 법정동 ---------   

, DF3 AS ( SELECT *
				,COUNT(H_CODE) AS SAME_Hcnt
                ,ROUND(행정동인구수/COUNT(H_CODE),2) AS 법정동인구수
			FROM DF
            GROUP BY H_CODE)

, DF4 AS ( SELECT A.*
				,B.SAME_Hcnt
				,B.법정동인구수 AS 법정동인구수CASE2	
			FROM DF2 A
				LEFT JOIN DF3 B ON A.H_CODE = B.H_CODE)

----------- CASE3 그리고 CASE1, CASE2 정리 -----------------
SELECT B_CODE
	, 시군구
	, 법정동
	, CASE	WHEN SAME_Hcnt = 1 and SAME_Bcnt > 1 THEN 법정동인구수CASE1 # CASE1 
			WHEN SAME_Bcnt = 1 and SAME_Hcnt > 1 THEN 법정동인구수CASE2  # CASE2
			WHEN SAME_Bcnt > 1 and SAME_Hcnt > 1 THEN ROUND(법정동인구수CASE1/SAME_Hcnt,2) #CASE3
			-- WHEN SAME_Bcnt = SAME_Hcnt THEN ROUND(법정동인구수CASE1/SAME_Hcnt,2)-- 
            ELSE 0 END AS 법정동인구수 
FROM DF4
