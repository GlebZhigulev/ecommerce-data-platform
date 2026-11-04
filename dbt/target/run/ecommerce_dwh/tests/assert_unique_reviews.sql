
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  SELECT
review_id, order_id
FROM "ecommerce"."dwh"."fact_reviews"
GROUP BY review_id, order_id
HAVING COUNT(*) > 1
  
  
      
    ) dbt_internal_test