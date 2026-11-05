SELECT 
order_purchase_timestamp::date AS order_date,
COUNT(DISTINCT order_id) as orders_count,
COUNT(order_item_id) as items_count,
SUM(price) as products_amount,
SUM(freight_value) as freight_amount,
SUM(total_value) as total_amount,
SUM(total_value) / NULLIF(COUNT(DISTINCT order_id), 0) as avg_order_value
FROM "ecommerce"."dwh"."fact_order_items" 
WHERE order_status = 'delivered'
GROUP BY order_purchase_timestamp::date