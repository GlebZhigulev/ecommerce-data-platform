
  
    

  create  table "ecommerce"."dwh"."dim_sellers__dbt_tmp"
  
  
    as
  
  (
    SELECT 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.sellers
  );
  