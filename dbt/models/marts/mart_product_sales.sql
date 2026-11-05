SELECT 
oi.product_id,
p.product_category_name_english,
COUNT(DISTINCT oi.order_id) as orders_count,
COUNT(oi.order_item_id) as items_sold,
SUM(oi.price) as products_amount,
SUM(oi.freight_value) as freight_amount,
SUM(oi.total_value) as total_amount,
AVG(oi.price) as avg_item_price
FROM {{ ref('fact_order_items') }} oi
LEFT JOIN {{ ref('dim_products') }} p on oi.product_id = p.product_id
WHERE oi.order_status = 'delivered'
GROUP BY oi.product_id, p.product_category_name_english