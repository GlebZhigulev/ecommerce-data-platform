
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select payment_sequential
from "ecommerce"."dwh"."fact_payments"
where payment_sequential is null



  
  
      
    ) dbt_internal_test