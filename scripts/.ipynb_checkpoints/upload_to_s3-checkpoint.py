from pathlib import Path
import kagglehub
import boto3
import os
from botocore.exceptions import ClientError


DATA_DIR = Path("/home/jovyan/work/data/raw")

csv_files = list(DATA_DIR.glob("*.csv"))

if len(csv_files) != 9:
    print("Скачиваем датасет с Kaggle...")
    kagglehub.dataset_download(
        "olistbr/brazilian-ecommerce",
        output_dir=str(DATA_DIR)
    )
else:
    print("Датасет уже скачан, пропускаем загрузку.")

if len(csv_files) != 9:
    raise ValueError(f"Ожидалось 9 CSV, найдено {len(csv_files)}")

for file in csv_files:
    print(f"{file.name}: {file.stat().st_size} байт")


def ensure_bucket(s3, bucket_name):
    try:
        s3.head_bucket(Bucket=bucket_name)

    except ClientError as e:
        status = e.response["ResponseMetadata"]["HTTPStatusCode"]

        if status != 404:
            raise

        s3.create_bucket(Bucket=bucket_name)
        print(f"Бакет '{bucket_name}' создан")

    else:
        print(f"Бакет '{bucket_name}' уже существует")


s3 = boto3.client(
    "s3",
    endpoint_url=os.environ["S3_ENDPOINT_URL"],
    aws_access_key_id=os.environ["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["AWS_SECRET_ACCESS_KEY"]
)

ensure_bucket(s3, "ecommerce-raw")




