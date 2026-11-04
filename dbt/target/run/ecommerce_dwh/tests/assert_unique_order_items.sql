
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  SELECT 
order_id, order_item_id
FROM "ecommerce"."dwh"."fact_order_items"
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
  
  
      
    ) dbt_internal_test