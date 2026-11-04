
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  SELECT
order_id, payment_sequential
FROM "ecommerce"."dwh"."fact_payments"
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1
  
  
      
    ) dbt_internal_test