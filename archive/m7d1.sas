%LET ROOT = /home/student;
%LET CSVDIR = &ROOT/shop_csv;
%LET ENC  =  utf-8;

libname SHOP "&ROOT/shop_db";

/* csv to sas macro */
%MACRO imp(name=);
   PROC IMPORT DATAFILE="&CSVDIR/&name..csv"
               OUT=SHOP.&name
               DBMS=CSV 
			   REPLACE;
      GETNAMES=YES;
      GUESSINGROWS=MAX;
   RUN;
   %put NOTE: ===== &name..csv  ->  shop.&name  변환 완료 =====;
%MEND;

CAS _ALL_ TERMINATE;
CAS mySession SESSOPTS=(CASLIB="CASUSER" TIMEOUT=1800);
CASLIB _ALL_ ASSIGN;
CASLIB _ALL_ LIST;

/* ── (1) 기존 글로벌 테이블 삭제 (PROMOTE REPLACE 호환 불가) ── */
PROC CASUTIL;
   DROPTABLE CASDATA="users"        INCASLIB="CASUSER" QUIET;
   DROPTABLE CASDATA="orders"       INCASLIB="CASUSER" QUIET;
   DROPTABLE CASDATA="order_items"  INCASLIB="CASUSER" QUIET;
   DROPTABLE CASDATA="products"     INCASLIB="CASUSER" QUIET;
   DROPTABLE CASDATA="monthly"      INCASLIB="CASUSER" QUIET;
   DROPTABLE CASDATA="categories"   INCASLIB="CASUSER" QUIET;
QUIT;

PROC CASUTIL;
   LOAD DATA=shop.users        OUTCASLIB="CASUSER" CASOUT="users"        PROMOTE;
   LOAD DATA=shop.orders       OUTCASLIB="CASUSER" CASOUT="orders"       PROMOTE;
   LOAD DATA=shop.order_items  OUTCASLIB="CASUSER" CASOUT="order_items"  PROMOTE;
   LOAD DATA=shop.products     OUTCASLIB="CASUSER" CASOUT="products"     PROMOTE;
   LOAD DATA=work.monthly      OUTCASLIB="CASUSER" CASOUT="monthly"      PROMOTE;
   LOAD DATA=shop.categories   OUTCASLIB="CASUSER" CASOUT="categories"   PROMOTE;
   LIST TABLES INCASLIB="CASUSER";
QUIT;
PROC CASUTIL;
   LOAD DATA=shop.orders       OUTCASLIB="CASUSER" CASOUT="orders"       PROMOTE;
   LIST TABLES INCASLIB="CASUSER";
QUIT;
/* shop_joined_data */
PROC FEDSQL SESSREF=mySession;
   CREATE TABLE CASUSER.shop_joined_data AS
   SELECT u.user_id, u.age, u.gender, u.channel, u.vip_grade,
          o.order_id, o.order_date, o.payment_method, o.total_amount,
          oi.item_id, oi.quantity, oi.unit_price,
          p.product_id, p.category_id, p.brand, p.price,
	  c.category_name
   FROM CASUSER.users u
   INNER JOIN CASUSER.orders      o  ON u.user_id     = o.user_id
   INNER JOIN CASUSER.order_items oi ON o.order_id    = oi.order_id
   INNER JOIN CASUSER.products    p  ON oi.product_id = p.product_id
   INNER JOIN CASUSER.categories  c  ON p.category_id = c.category_id;
QUIT;

PROC CASUTIL;
   PROMOTE CASDATA="shop_joined_data" INCASLIB="CASUSER" OUTCASLIB="CASUSER";
QUIT;


PROC FEDSQL SESSREF=mySession;
   CREATE TABLE CASUSER.channel_kpi AS
   SELECT u.channel,
          (SUM(o.total_amount) - SUM(o.total_amount) * 0.6) /
           SUM(o.total_amount)              AS margin_rate,
          SUM(o.total_amount) /
             COUNT(DISTINCT o.user_id)       AS aov,
          COUNT(DISTINCT o.user_id) * 1.0 /
             COUNT(DISTINCT u.user_id)       AS conversion_rate
   FROM CASUSER.users u
   LEFT JOIN CASUSER.orders o ON u.user_id = o.user_id
   GROUP BY u.channel;
QUIT;

PROC CASUTIL;
   PROMOTE CASDATA="channel_kpi" INCASLIB="CASUSER" OUTCASLIB="CASUSER";
QUIT;


/*  */


TITLE "[S3 지원 - ROI] 채널별 실제 ROI";

PROC FEDSQL SESSREF=mySession;
   CREATE TABLE CASUSER.channel_roi AS
   SELECT u.channel,
          COUNT(DISTINCT u.user_id)              AS n_users,
          COUNT(DISTINCT o.user_id)              AS buyer_count,
          SUM(o.total_amount)                    AS revenue,
          /* 매출 × 40% = 이익 (60% 는 원가/운영비 가정) */
          SUM(o.total_amount) * 0.4              AS profit,
          /* 채널별 사용자당 마케팅 비용 (CAC 가정) */
          CASE u.channel
             WHEN 'organic'     THEN COUNT(DISTINCT u.user_id) * 2000
             WHEN 'paid_search' THEN COUNT(DISTINCT u.user_id) * 8000
             WHEN 'social'      THEN COUNT(DISTINCT u.user_id) * 5000
             WHEN 'referral'    THEN COUNT(DISTINCT u.user_id) * 1500
             WHEN 'email'       THEN COUNT(DISTINCT u.user_id) * 500
             WHEN 'other'       THEN COUNT(DISTINCT u.user_id) * 3000
             ELSE COUNT(DISTINCT u.user_id) * 5000
          END                                    AS marketing_cost,
          /* ROI = (이익 - 마케팅비) / 마케팅비 * 100 */
          (SUM(o.total_amount) * 0.4 -
             CASE u.channel
                WHEN 'organic'     THEN COUNT(DISTINCT u.user_id) * 2000
                WHEN 'paid_search' THEN COUNT(DISTINCT u.user_id) * 8000
                WHEN 'social'      THEN COUNT(DISTINCT u.user_id) * 5000
                WHEN 'referral'    THEN COUNT(DISTINCT u.user_id) * 1500
                WHEN 'email'       THEN COUNT(DISTINCT u.user_id) * 500
                WHEN 'other'       THEN COUNT(DISTINCT u.user_id) * 3000
                ELSE COUNT(DISTINCT u.user_id) * 5000
             END
          ) * 100.0 /
             CASE u.channel
                WHEN 'organic'     THEN COUNT(DISTINCT u.user_id) * 2000
                WHEN 'paid_search' THEN COUNT(DISTINCT u.user_id) * 8000
                WHEN 'social'      THEN COUNT(DISTINCT u.user_id) * 5000
                WHEN 'referral'    THEN COUNT(DISTINCT u.user_id) * 1500
                WHEN 'email'       THEN COUNT(DISTINCT u.user_id) * 500
                WHEN 'other'       THEN COUNT(DISTINCT u.user_id) * 3000
                ELSE COUNT(DISTINCT u.user_id) * 5000
             END                                 AS roi
   FROM CASUSER.users u
   LEFT JOIN CASUSER.orders o ON u.user_id = o.user_id
   GROUP BY u.channel;
QUIT;

/* 검증 - ROI 결과 확인 */
PROC SQL OUTOBS=10;
   SELECT channel,
          n_users FORMAT=COMMA10.,
          revenue FORMAT=COMMA15.,
          marketing_cost FORMAT=COMMA15.,
          roi FORMAT=8.1
   FROM CASUSER.channel_roi
   ORDER BY roi DESC;
QUIT;

PROC CASUTIL;
   PROMOTE CASDATA="channel_roi" INCASLIB="CASUSER" OUTCASLIB="CASUSER";
QUIT;

/*--- session 4 ---*/
TITLE "[S4 지원] VIP 매출 + ARPU";
PROC FEDSQL SESSREF=mySession;
   CREATE TABLE CASUSER.vip_analysis AS
   SELECT u.vip_grade,
          COUNT(DISTINCT u.user_id)    AS n_members,
          SUM(o.total_amount)          AS revenue,
          SUM(o.total_amount) /
             COUNT(DISTINCT u.user_id) AS arpu
   FROM CASUSER.users u
   LEFT JOIN CASUSER.orders o ON u.user_id = o.user_id
   GROUP BY u.vip_grade;
QUIT;

PROC CASUTIL;
   PROMOTE CASDATA="vip_analysis" INCASLIB="CASUSER" OUTCASLIB="CASUSER";
QUIT;
TITLE;




/* 폭포수 그래프 */
PROC FEDSQL SESSREF=mySession;
   CREATE TABLE CASUSER.orders_monthly_raw AS
   SELECT YEAR(order_date) AS yr, MONTH(order_date) AS mo,
          SUM(total_amount) AS raw_total
   FROM CASUSER.orders
   GROUP BY YEAR(order_date), MONTH(order_date);
QUIT;

/* 1) 특정 월에 비수기 느낌으로 조정 - 폭포 차트 시연용 */
PROC FEDSQL SESSREF=mySession;
   CREATE TABLE CASUSER.orders_monthly_adj AS
   SELECT cur.yr, cur.mo,
          CASE cur.mo
             WHEN 2  THEN prev.raw_total * 0.70
             WHEN 8  THEN prev.raw_total * 0.75
             WHEN 11 THEN prev.raw_total * 0.85
             ELSE cur.raw_total
          END AS total_amount
   FROM CASUSER.orders_monthly_raw cur
   LEFT JOIN CASUSER.orders_monthly_raw prev
      ON prev.yr = cur.yr AND prev.mo = cur.mo - 1;
QUIT;

PROC CASUTIL;
   DROPTABLE CASDATA="orders_monthly_delta" INCASLIB="CASUSER" QUIET;
QUIT;

PROC FEDSQL SESSREF=mySession;
   CREATE TABLE CASUSER.orders_monthly_delta AS
   SELECT cur.yr, cur.mo,
          cur.total_amount - COALESCE(prev.total_amount, 0) AS delta_amount
   FROM CASUSER.orders_monthly_adj cur
   LEFT JOIN CASUSER.orders_monthly_adj prev
      ON prev.yr = cur.yr AND prev.mo = cur.mo - 1;
QUIT;

PROC CASUTIL;
   PROMOTE CASDATA="orders_monthly_delta" INCASLIB="CASUSER" OUTCASLIB="CASUSER";
QUIT;












