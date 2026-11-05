
  
    

  create  table "ecommerce"."dwh_marts"."mart_delivery_performance__dbt_tmp"
  
  
    as
  
  (
    SELECT 
order_purchase_timestamp::date as order_date,
COUNT(order_id) as delivered_orders_count,
COUNT(is_delayed) AS evaluated_deliveries_count,
COUNT(*) FILTER (WHERE is_delayed = FALSE) as on_time_orders_count,
COUNT(*) FILTER (WHERE is_delayed = TRUE) as delayed_orders_count,
AVG(delivery_days) as avg_delivery_days,
100.0 * COUNT(*) FILTER (WHERE is_delayed = TRUE)
    / NULLIF(COUNT(is_delayed), 0) AS delay_rate_pct
FROM "ecommerce"."dwh"."fact_orders"
WHERE order_status = 'delivered'
GROUP BY order_purchase_timestamp::date
  );
  