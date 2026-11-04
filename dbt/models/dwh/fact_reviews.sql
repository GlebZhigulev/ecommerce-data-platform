SELECT 
r.review_id,
r.order_id,
o.customer_id,
r.review_score,
r.review_comment_title,
r.review_comment_message,
r.review_creation_date,
r.review_answer_timestamp
FROM staging.order_reviews r
LEFT JOIN staging.orders o on r.order_id = o.order_id
