
import os
from contextlib import closing

import boto3
import psycopg2
from psycopg2 import sql


BUCKET = "ecommerce-raw"

TABLES = {
    "staging.orders": "olist/olist_orders_dataset.csv",
    "staging.customers": "olist/olist_customers_dataset.csv",
    "staging.order_items": "olist/olist_order_items_dataset.csv",
    "staging.order_payments": "olist/olist_order_payments_dataset.csv",
    "staging.order_reviews": "olist/olist_order_reviews_dataset.csv",
    "staging.products": "olist/olist_products_dataset.csv",
    "staging.sellers": "olist/olist_sellers_dataset.csv",
    "staging.geolocation": "olist/olist_geolocation_dataset.csv",
    "staging.product_category_name_translation": "olist/product_category_name_translation.csv",
}


def load_table(s3, conn, bucket, key, table):
    schema_name, table_name = table.split(".", 1)
    table_id = sql.Identifier(schema_name, table_name)

    truncate_query = sql.SQL(
        "TRUNCATE TABLE {}"
    ).format(table_id)

    copy_query = sql.SQL(
        "COPY {} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)"
    ).format(table_id)

    count_query = sql.SQL(
        "SELECT COUNT(*) FROM {}"
    ).format(table_id)

    response = s3.get_object(
        Bucket=bucket,
        Key=key
    )

    with closing(response["Body"]) as csv_file:
        with conn:
            with conn.cursor() as cursor:

                cursor.execute(truncate_query)

                cursor.copy_expert(
                    sql=copy_query.as_string(conn),
                    file=csv_file
                )

                cursor.execute(count_query)
                
                rows_count = cursor.fetchone()[0]

    print(f"[SUCCESS] {table}: {rows_count} rows")


def main():
    s3 = boto3.client(
        "s3",
        endpoint_url=os.environ["S3_ENDPOINT_URL"],
        aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"]
    )

    conn = psycopg2.connect(
        dbname=os.environ["POSTGRES_DB"],
        host=os.environ["POSTGRES_HOST"],
        port=os.environ["POSTGRES_PORT"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"]
    )

    try:
        for table, key in TABLES.items():
            load_table(s3, conn, BUCKET, key, table)
    finally:
        conn.close()
        s3.close()


if __name__ == "__main__":
    main()
