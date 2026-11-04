SELECT
review_id, order_id
FROM "ecommerce"."dwh"."fact_reviews"
GROUP BY review_id, order_id
HAVING COUNT(*) > 1