SELECT 
order_id,
customer_id,
order_status,
order_purchase_timestamp,
order_approved_at,
order_delivered_carrier_date,
order_delivered_customer_date,
order_estimated_delivery_date,
EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0 as delivery_days,
CASE 
    WHEN order_delivered_customer_date::date > order_estimated_delivery_date::date THEN TRUE 
    WHEN order_delivered_customer_date::date <= order_estimated_delivery_date::date THEN FALSE
ELSE 
    NULL
END as is_delayed
FROM staging.orders