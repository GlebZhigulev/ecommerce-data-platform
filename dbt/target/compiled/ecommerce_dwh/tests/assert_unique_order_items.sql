SELECT 
order_id, order_item_id
FROM "ecommerce"."dwh"."fact_order_items"
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1