SELECT
oi.order_id,
oi.order_item_id,
o.customer_id,
oi.product_id,
oi.seller_id,
o.order_purchase_timestamp,
o.order_status,
oi.shipping_limit_date,
oi.price,
oi.freight_value,
oi.price + oi.freight_value as total_value
FROM staging.order_items oi
LEFT JOIN staging.orders o on oi.order_id = o.order_id