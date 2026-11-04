SELECT
op.order_id,
op.payment_sequential,
o.customer_id,
op.payment_type,
op.payment_installments,
op.payment_value,
o.order_purchase_timestamp
FROM staging.order_payments op
LEFT JOIN staging.orders o on op.order_id = o.order_id