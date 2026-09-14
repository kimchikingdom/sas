/* =========================================================
   1단계: 4개 데이터셋 조인 및 마스터 데이터 생성 (work.exec_master)
   ========================================================= */
proc sql;
    create table work.exec_master as
    select 
        /* 주문 및 고객 정보 */
        o.order_id,
        o.user_id,
        o.shipping_region,
        o.status,
        o.order_date,
        
        /* 상품 및 카테고리 정보 */
        oi.product_id,
        p.product_name,
        c.category_name,
        
        /* 수량 및 금액/마진 계산 */
        oi.quantity,
        oi.unit_price,
        oi.item_discount,
        
        /* 핵심 측정값 계산 */
        oi.line_total as line_revenue label='매출액',
        (oi.quantity * p.cost) as line_cost label='매출원가',
        (oi.line_total - (oi.quantity * p.cost)) as line_profit label='영업이익'


    from shop.orders as o
    inner join shop.order_items as oi on o.order_id = oi.order_id
    inner join shop.products as p    on oi.product_id = p.product_id
    left  join shop.categories as c  on p.category_id = c.category_id;
quit;





proc casutil;
    load data=exec_master 
         outcaslib="casuser" 
         casout="exec_master" 
         promote;
quit;

