/*
Seller ID Category Sales (Millions VND)
1           Book    258
2       Electronics 299
3       Electronics 123
4           Book    272
5           FMCG    485
6           Book    187
7           FMCG    349
8           FMCG    61
9       Electronics 321
10          FMCG    20
*/

--a. Write a SQL query to find the best seller by each category
---a. Tạo bảng Sale_X
CREATE DATABASE TESTOCB
CREATE TABLE SALE_X 
 (SELLER_ID INT,
  CATEGORY VARCHAR(20),
  SALES_MILLIONS_VND FLOAT)

INSERT INTO SALE_X (SELLER_ID, CATEGORY, SALES_MILLIONS_VND)
VALUES ('1', 'Book', '258'),
       ('2', 'Electronics', '299'),
	   ('3', 'Electronics', '123'),
	   ('4', 'Book', '272'),
	   ('5', 'FMCG', '485'),
	   ('6', 'Book', '187'),
	   ('7', 'FMCG', '349'),
       ('8', 'FMCG', '61'),
	   ('9', 'Electronics', '321'),
	   ('10', 'FMCG', '20')

WITH CTE AS 
(SELECT SELLER_ID, CATEGORY, MAX(SALES_MILLIONS_VND) AS REVENUE,
        ROW_NUMBER() OVER(PARTITION BY CATEGORY ORDER BY MAX(SALES_MILLIONS_VND) DESC) AS ROW_NUM
FROM SALE_X
GROUP BY SELLER_ID, CATEGORY)

SELECT * FROM CTE 
WHERE ROW_NUM = 1

--- CÔ:
SELECT T.SELLER_ID,
       T.CATEGORY,
	   T.SALES_MILLIONS_VND
FROM
     (SELECT *,
             ROW_NUMBER () OVER (PARTITION BY CATEGORY ORDER BY SALES_MILLIONS_VND DESC) AS ROWNUM
     FROM SALE_X) AS T
WHERE T.ROWNUM = 1

--b. Give three following columns in table Y
---B1. Tạo bảng Award_Y
CREATE TABLE AWARD_Y
  (AWARD_YEAR INT,
   AWARD VARCHAR(20),
   SELLER_ID INT)

INSERT INTO AWARD_Y (AWARD_YEAR, AWARD, SELLER_ID)
VALUES
      ('2017', 'BEST SELLER', '9'),
	  ('2018', 'BEST SELLER', '5'),
	  ('2017', 'BEST OPERATIONS', '5'),
	  ('2018', 'BEST QUALITY', '10'),
	  ('2018', 'BEST OPERATIONS', '6'),
	  ('2017', 'BEST SELLER', '4'),
	  ('2017', 'BEST OPERATIONS', '5'),
	  ('2017', 'BEST QUALITY', '7'),
	  ('2017', 'BEST QUALITY', '10')

---B2.Write a SQL query to find of 3 best sellers in (a), how many award did they received in 2017.
WITH CTE AS
(SELECT T2.AWARD_YEAR,
        T1.SELLER_ID,
        T1.CATEGORY,
	    T1.SALES_MILLIONS_VND,
        COUNT(T2.AWARD) AS TOTAL_AWARD,
        ROW_NUMBER () OVER (PARTITION BY T1.CATEGORY ORDER BY T1.SALES_MILLIONS_VND DESC) AS ROWNUM
FROM SALE_X T1
LEFT JOIN AWARD_Y T2
ON T1.SELLER_ID = T2.SELLER_ID
WHERE AWARD_YEAR = '2017'
GROUP BY T2.AWARD_YEAR,
         T1.SELLER_ID,
         T1.CATEGORY,
	     T1.SALES_MILLIONS_VND)  --- TẠO BẢNG GỒM CÁC CỘT NĂM 2017

SELECT CTE.SELLER_ID, 
       CTE.CATEGORY, 
       CTE.TOTAL_AWARD,
       CTE.ROWNUM 
FROM CTE
WHERE ROWNUM = 1

--- CODE CÔ:
SELECT T4.SELLER_ID,
       T4.CATEGORY, 
	   T4.AWARD_IN_2017
FROM 
      (SELECT T3.SELLER_ID,
              T3.CATEGORY,
              T3.SALES_MILLIONS_VND,
	          T3.AWARD,
	          COUNT(T3.AWARD_YEAR) AS AWARD_IN_2017,
		      ROW_NUMBER () OVER (PARTITION BY T3.CATEGORY ORDER BY T3.SALES_MILLIONS_VND DESC) AS ROWNUM_SALES
      FROM
         (SELECT T1.SELLER_ID,
                 T1.CATEGORY,
		         T1.SALES_MILLIONS_VND,
	             T2.AWARD,
	             T2.AWARD_YEAR
         FROM SALE_X AS T1
         LEFT JOIN AWARD_Y AS T2 ON T1.SELLER_ID = T2.SELLER_ID) AS T3
      WHERE T3.AWARD IS NOT  NULL AND T3.AWARD_YEAR IS NOT NULL
      GROUP BY T3.SELLER_ID,
               T3.CATEGORY,
	           T3.SALES_MILLIONS_VND,
	           T3.AWARD) AS T4
WHERE T4.ROWNUM_SALES = 1

     
/*
Câu 2.
a. Write a SQL query to find the number of product that were available for sales at the end of each month.
*/
SELECT * FROM [TESTOCB].[dbo].[product_history]

ALTER TABLE [TESTOCB].[dbo].[product_history]
ALTER COLUMN DATE DATE
---
SELECT T1.YEAR,
       T1.MONTH,
       T2.PRODUCT_ID,
       T2.STOCK
FROM
(SELECT YEAR(DATE) AS YEAR,
        MONTH(DATE) AS MONTH,
        MAX(DAY(DATE)) AS LAST_DAY --- LẤY NGÀY CUỐI THÁNG VỚI PRODUCT_ID CÓ HÀNG
FROM [TESTOCB].[dbo].[product_history]
WHERE PRODUCT_STATUS = 'ON' --- ON LÀ CÓ HÀNG
GROUP BY YEAR(DATE),
         MONTH(DATE)) AS T1
--- JOIN NGƯỢC LẠI ĐỂ LẤY STOCK VÀ PRODUCT_ID
LEFT JOIN
(SELECT *,          ---Ý TƯỞNG LÀ TẠO RA BẢNG GỒM CÁC CỘT YEAR, MONTH, DAY
YEAR(DATE) AS YEAR,
MONTH(DATE) AS MONTH,
DAY(DATE) AS DAY
FROM [TESTOCB].[dbo].[product_history]
WHERE PRODUCT_STATUS = 'ON') AS T2
ON T2.DAY = T1.LAST_DAY AND T1.MONTH = T2.MONTH AND T1.YEAR = T2.YEAR
ORDER BY T1.YEAR DESC, T1.MONTH DESC

--b. Average stock is calculated as: Total stock in a month/ total date in a month. Write a SQL query to find Product ID with the most “average stock” by month.
--t1: Lấy danh sách những ngày lớn nhất trong tháng của từng product_id
--t3: Lấy total_stock của product_id trong tháng � stock tại ngày lớn nhất của Product_id) và đánh ranking avg_stock của từng product_id từng tháng
--t4: Lọc lấy ds product_id có tồn kho lớn nhất tại từng tháng
SELECT * FROM
   (SELECT
    T1.*,
    T2.STOCK AS TOTAL_STOCK_IN_MONTH,
    T2.STOCK/T1.TOTAL_DAYS_IN_MONTH AS AVG_STOCK,
    ROW_NUMBER() OVER(PARTITION BY T1.YEAR_DATE, T1.MONTH_DATE,
    T1.TOTAL_DAYS_IN_MONTH ORDER BY T2.STOCK/T1.TOTAL_DAYS_IN_MONTH DESC) AS ROW_NUM    
    FROM
   (SELECT
    YEAR([date]) AS YEAR_DATE,
    MONTH([date]) AS MONTH_DATE,
    MAX([date]) AS DATE,
    DAY(EOMONTH([date])) AS TOTAL_DAYS_IN_MONTH, ---> LẤY SỐ NGÀY TRONG THÁNG (VD: THÁNG 5 CÓ 31 NGÀY THÌ TRẢ VỀ 31)
    PRODUCT_ID
    FROM [TESTOCB].[DBO].[PRODUCT_HISTORY]
    GROUP BY
    YEAR([date]),
    MONTH([date]),
    DAY(EOMONTH([date])),
    PRODUCT_ID) AS T1 
    LEFT JOIN [TESTOCB].[DBO].[PRODUCT_HISTORY] AS T2
    ON T1.PRODUCT_ID = T2.PRODUCT_ID) AS T3
    WHERE ROW_NUM = 1 

--- BÀI 1.
--- TẠO BẢNG:
CREATE TABLE SALE_X1
(SELLER_ID INT,
CATEGORY VARCHAR(20),
SALES_MILIIONS_VND FLOAT)
--- THÊM DỮ LIỆU VÀO
INSERT INTO SALE_X1 (SELLER_ID, CATEGORY, SALES_MILIIONS_VND)
VALUES ('1','Book','258'),
       ('2','Electronics','299'),
       ('3','Electronics','123'),
       ('4','Book','272'),
       ('5','FMCG','485'),
       ('6','Book','187'),
       ('7','FMCG','349'),
       ('8','FMCG','61'),
       ('9','Electronics','321'),
       ('10','FMCG','20')
--- CÂU 1A. VIẾT QUERY TÌM RA BEST SELLER CỦA MỖI HẠNG MỤC
--- Ý TƯỞNG: NHÓM THEO CATEGORY, ĐÁNH RANK ĐỂ LẤY SỐ TIỀN SALES LỚN NHẤT MỖI MỤC
WITH CTE AS
(SELECT SELLER_ID, CATEGORY, MAX(SALES_MILIIONS_VND) AS REVENUE,
        ROW_NUMBER() OVER(PARTITION BY CATEGORY ORDER BY MAX(SALES_MILIIONS_VND) DESC) AS ROW_NUM
FROM SALE_X1
GROUP BY SELLER_ID, CATEGORY)
SELECT SELLER_ID, CATEGORY, REVENUE FROM CTE WHERE ROW_NUM = 1
--- CÂU 1B. CHO 3 CỘT TRONG BẢNG Y DƯỚI ĐÂY
--- TẠO BẢNG AWARD_Y1
CREATE TABLE AWARD_Y1
(AWARD_YEAR INT,
AWARD VARCHAR(20),
SELLER_ID INT)
--- THÊM DỮ LIỆU VÀO
INSERT INTO AWARD_Y1(AWARD_YEAR, AWARD, SELLER_ID)
VALUES ('2017','Best Seller','9'),
       ('2018','Best Seller','5'),
       ('2017','Best Operations','5'),
       ('2018','Best Quality','10'),
       ('2018','Best Operations','6'),
       ('2017','Best Seller','4'),
       ('2017','Best Operations','5'),
       ('2017','Best Quality','7'),
       ('2017','Best Quality','10')
--- TÌM RA 3 BEST SELLER Ở CÂU A, CÓ BAO NHIÊU GIẢI THƯỞNG ĐƯỢC NHẬN VÀO NĂM 2017
--- Ý TƯỞNG: CHO 2 BẢNG SALE_X VÀ AWARD_YEAR NĂM 2017 JOIN VỚI NHAU SAU ĐÓ TẠO RA CỘT AWARD_YEAR,SELLER_ID,CATEGORY,SALES_MILLIONS_VND,COUNT(AWARD), ĐÁNH RANK RỒI SẮP XẾP THEO SỐ TIỀN CAO NHẤT
--- LẤY NHỮNG CATEGORY CÓ ROWNUM = 1
WITH CTE AS
(SELECT T2.AWARD_YEAR,
        T1.SELLER_ID,
        T1.CATEGORY,
	    T1.SALES_MILLIONS_VND,
        COUNT(T2.AWARD) AS TOTAL_AWARD,
        ROW_NUMBER () OVER (PARTITION BY T1.CATEGORY ORDER BY T1.SALES_MILLIONS_VND DESC) AS ROWNUM
FROM SALE_X T1
LEFT JOIN AWARD_Y T2
ON T1.SELLER_ID = T2.SELLER_ID
WHERE AWARD_YEAR = '2017'
GROUP BY T2.AWARD_YEAR,
         T1.SELLER_ID,
         T1.CATEGORY,
	     T1.SALES_MILLIONS_VND)  --- TẠO BẢNG GỒM CÁC CỘT NĂM 2017

SELECT CTE.SELLER_ID, 
       CTE.CATEGORY, 
       CTE.TOTAL_AWARD,
       CTE.ROWNUM 
FROM CTE
WHERE ROWNUM = 1

--- CÂU 2. VIẾT QUERY TÌM SỐ LƯỢNG SẢN PHẨM CÓ SẴN VÀO CUỐI MỖI THÁNG.
Select t1.year,
t1.month,t2.product_id,
t2.stock
from
--- Lấy ngày cuối tháng với product_id có hàng
(Select YEAR(date) as year,
MONTH(date) as month,
max(day(date)) as last_day
from Product_History
where product_status = 'On'
group by YEAR(date),
MONTH(date)) as t1
left join 
(select *,
year(date) as year,
month(date) as month,
day(date) as day
from product_history
where product_status='On') as t2
on t2.day = t1.last_day and t1.month = t2.month and t1.year = t2.year
order by t1.year desc, t1.month desc

