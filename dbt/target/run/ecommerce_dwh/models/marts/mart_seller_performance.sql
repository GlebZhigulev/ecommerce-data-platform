
  
    

  create  table "ecommerce"."dwh_marts"."mart_seller_performance__dbt_tmp"
  
  
    as
  
  (
    SELECT 
s.seller_id, 
s.seller_city, 
s.seller_state,
COUNT(DISTINCT oi.order_id) as orders_count,
COUNT(oi.order_item_id) as items_sold,
COUNT (DISTINCT oi.product_id) as unique_products_sold,
COALESCE(SUM(oi.price), 0) as products_amount,
COALESCE(SUM(oi.freight_value),0) as freight_amount,
COALESCE(SUM(oi.total_value),0) as total_amount,
SUM(oi.total_value) / NULLIF(COUNT(DISTINCT oi.order_id), 0) as avg_order_value
FROM "ecommerce"."dwh"."dim_sellers" s
LEFT JOIN "ecommerce"."dwh"."fact_order_items" oi
    ON s.seller_id = oi.seller_id
    AND oi.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_city, s.seller_state
  );
  