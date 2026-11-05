
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select order_date
from "ecommerce"."dwh_marts"."mart_daily_sales"
where order_date is null



  
  
      
    ) dbt_internal_test