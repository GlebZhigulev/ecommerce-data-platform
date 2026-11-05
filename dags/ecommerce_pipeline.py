from datetime import datetime, timedelta
from airflow.operators.bash import BashOperator
from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

default_args = {
    'owner': 'admin',
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

with DAG(
    dag_id ="ecommerce_pipeline",
    start_date = datetime(2026,11,5),
    schedule = None,
    catchup = False,
    default_args=default_args,
    template_searchpath="/opt/airflow/sql"
) as dag:
    upload_to_s3 = BashOperator(
        task_id="upload_to_s3",
        bash_command="python /opt/airflow/scripts/upload_to_s3.py"
    )

    create_staging_tables = SQLExecuteQueryOperator(
        task_id="create_staging_tables",
        conn_id="ecommerce_postgres",
        sql="staging_DDL.sql",
        split_statements=True,
        autocommit=False
    )

    load_staging = BashOperator(
        task_id = "load_staging",
        bash_command="python /opt/airflow/scripts/load_staging.py"
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command="cd /opt/airflow/dbt && dbt build"
    )


upload_to_s3 >> create_staging_tables >> load_staging >> dbt_build