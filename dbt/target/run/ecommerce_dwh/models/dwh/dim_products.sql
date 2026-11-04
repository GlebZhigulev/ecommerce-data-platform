
  
    

  create  table "ecommerce"."dwh"."dim_products__dbt_tmp"
  
  
    as
  
  (
    SELECT 
p.product_id,
p.product_category_name,
pct.product_category_name_english,
p.product_photos_qty,
p.product_weight_g,
p.product_length_cm,
p.product_height_cm,
p.product_width_cm,
p.product_length_cm * p.product_height_cm * p.product_width_cm as product_volume_cm3
FROM staging.products p
LEFT JOIN staging.product_category_name_translation pct ON p.product_category_name = pct.product_category_name
  );
  