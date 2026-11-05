
    
    

select
    product_id as unique_field,
    count(*) as n_records

from "ecommerce"."dwh_marts"."mart_product_sales"
where product_id is not null
group by product_id
having count(*) > 1


