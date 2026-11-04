SELECT
order_id, payment_sequential
FROM "ecommerce"."dwh"."fact_payments"
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1