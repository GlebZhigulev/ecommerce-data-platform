# E-commerce Data Platform

Учебно-практический проект по построению **ETL/ELT-пайплайна** для данных интернет-магазина. Проект охватывает получение исходных данных, хранение RAW, загрузку в PostgreSQL, моделирование аналитического хранилища, создание витрин и оркестрацию через Apache Airflow.

**Основной результат:** четыре задачи в Airflow запускают весь путь от исходных CSV до готовых аналитических таблиц и dbt-тестов.

## Архитектура

```text
Kaggle — Brazilian E-Commerce Public Dataset by Olist
                       |
                       v
            Python: upload_to_s3.py
                       |
                       v
                MinIO (RAW / S3)
                       |
                       v
          Python: load_staging.py
                       |
                       v
             PostgreSQL: staging
                  9 таблиц
                       |
                       v
                dbt: DWH (dwh)
          4 факта + 3 измерения
                       |
                       v
             dbt: MARTS (dwh_marts)
                4 витрины
```

**Apache Airflow** управляет последовательностью этапов, повторными попытками и логами выполнения. SQL-файл с DDL позволяет создать таблицы STAGING до загрузки CSV.

### Технологии

| Технология | Назначение |
|---|---|
| Python, `boto3`, `kagglehub`, `psycopg2` | Получение данных, работа с MinIO и загрузка в PostgreSQL |
| MinIO | S3-совместимое RAW-хранилище исходных CSV |
| PostgreSQL 16 | STAGING, DWH и аналитические витрины |
| dbt Core + dbt-postgres | SQL-преобразования, зависимости моделей, тесты |
| Apache Airflow 2.10.3 | Оркестрация пайплайна |
| Docker Compose | Локальное развёртывание сервисов |
| JupyterLab | Среда разработки и исследования данных |
| Apache Superset | BI-инструмент в инфраструктуре; подключение дашбордов отложено |

## Источник данных

[**Brazilian E-Commerce Public Dataset by Olist**](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — публичный набор данных электронной коммерции из девяти CSV-файлов: заказы, покупатели, позиции заказов, платежи, отзывы, товары, продавцы, геолокация и перевод категорий товаров.

Скрипт `scripts/upload_to_s3.py` получает файлы и размещает их в бакете `ecommerce-raw` по префиксу `olist/`. Загрузка в STAGING выполняется непосредственно из MinIO, без необходимости вручную импортировать CSV через DBeaver.

## Модель данных

### STAGING

В схеме `staging` находятся девять таблиц, соответствующих исходным файлам:

| Таблица | Строк в исходной загрузке |
|---|---:|
| `staging.orders` | 99 441 |
| `staging.customers` | 99 441 |
| `staging.order_items` | 112 650 |
| `staging.order_payments` | 103 886 |
| `staging.order_reviews` | 99 224 |
| `staging.products` | 32 951 |
| `staging.sellers` | 3 095 |
| `staging.geolocation` | 1 000 163 |
| `staging.product_category_name_translation` | 71 |

Структура таблиц описана в `sql/staging_DDL.sql`. Для повторных запусков используются `CREATE SCHEMA IF NOT EXISTS` и `CREATE TABLE IF NOT EXISTS`.

Загрузчик `scripts/load_staging.py` читает CSV через S3 API и использует PostgreSQL `COPY` для загрузки. STAGING обновляется полной перезагрузкой, а не добавлением новых строк к предыдущей копии.

### DWH (`dwh`)

Хранилище строится с помощью dbt. Модели разделены на таблицы фактов и измерений.

**Измерения**

| Модель | Содержание |
|---|---|
| `dim_customers` | Покупатели, идентификаторы и географические атрибуты |
| `dim_products` | Товары, категории с английскими названиями, характеристики и вычисленный объём |
| `dim_sellers` | Продавцы и их географические атрибуты |

**Факты**

| Модель | Гранулярность | Содержание |
|---|---|---|
| `fact_orders` | Один заказ | Статусы, даты, длительность доставки, признак задержки |
| `fact_order_items` | Одна позиция заказа | Товар, продавец, цена, доставка и сумма позиции |
| `fact_payments` | Одна запись платежа | Способ оплаты, количество рассрочек, сумма |
| `fact_reviews` | Один отзыв в рамках заказа | Оценка, текст, даты отзыва и ответа |

### MARTS (`dwh_marts`)

Четыре аналитические витрины:

| Витрина | Гранулярность | Что позволяет анализировать |
|---|---|---|
| `mart_daily_sales` | День покупки | Количество заказов и позиций, выручку по товарам, стоимость доставки, средний чек |
| `mart_product_sales` | Товар | Продажи и выручку по товарам, категории, среднюю цену позиции |
| `mart_seller_performance` | Продавец | Количество заказов, проданных позиций и товаров, выручку и средний чек |
| `mart_delivery_performance` | День покупки | Количество доставок, своевременность, среднюю длительность и долю задержек |

Для показателей продаж используются **заказы со статусом `delivered`**. Сумма позиции включает цену товара и стоимость доставки (`price + freight_value`), поэтому совокупный оборот в соответствующих витринах учитывает обе составляющие. В витрине продавцов сохраняются также продавцы без доставленных заказов.

## Оркестрация в Airflow

DAG: **`ecommerce_pipeline`**. Запускается вручную (`schedule=None`, `catchup=False`). Для задач настроена одна повторная попытка с интервалом пять минут.

```text
upload_to_s3
     |
     v
create_staging_tables
     |
     v
load_staging
     |
     v
dbt_build
```

| Задача | Оператор | Действие |
|---|---|---|
| `upload_to_s3` | `BashOperator` | Запускает `scripts/upload_to_s3.py` |
| `create_staging_tables` | `SQLExecuteQueryOperator` | Выполняет `sql/staging_DDL.sql` |
| `load_staging` | `BashOperator` | Запускает `scripts/load_staging.py` |
| `dbt_build` | `BashOperator` | Выполняет `dbt build` — модели и тесты |

## Структура репозитория

```text
ecommerce-data-platform/
├── dags/
│   └── ecommerce_pipeline.py
├── scripts/
│   ├── upload_to_s3.py
│   └── load_staging.py
├── sql/
│   └── staging_DDL.sql
├── dbt/
│   ├── models/
│   │   ├── dwh/
│   │   └── marts/
│   ├── tests/
│   ├── dbt_project.yml
│   └── profiles.yml
├── jupyter/
│   └── Dockerfile
├── superset/
│   └── superset_config.py
├── data/                  
├── logs/                 
├── docker-compose.yml
├── Dockerfile.airflow
├── Dockerfile.dbt
├── .env                   
├── .gitignore
└── README.md
```

## Локальный запуск

### 1. Требования

- Docker Desktop с поддержкой Docker Compose.
- Доступ к интернету для получения открытого датасета Kaggle и Docker-образов.
- Достаточно свободного места и памяти для PostgreSQL, MinIO, Airflow и dbt.

### 2. Переменные окружения

Создать `.env` в корне проекта. Файл не должен попадать в Git. Docker Compose использует следующие переменные:

```dotenv
POSTGRES_PASSWORD=<your_password>
MINIO_ROOT_USER=<your_minio_user>
MINIO_ROOT_PASSWORD=<your_minio_password>
AIRFLOW_DB_PASSWORD=<your_password>
AIRFLOW_FERNET_KEY=<your_fernet_key>
AIRFLOW_WEBSERVER_SECRET_KEY=<your_secret_key>
AIRFLOW_ADMIN_PASSWORD=<your_password>
JUPYTER_TOKEN=<your_token>
SUPERSET_DB_PASSWORD=<your_password>
SUPERSET_ADMIN_PASSWORD=<your_password>
SUPERSET_SECRET_KEY=<your_secret_key>
```

Значения в угловых скобках — примеры, их необходимо заменить собственными. Пароли и ключи не публиковать.

### 3. Запуск необходимых сервисов

Из корня репозитория:

```bash
docker compose config --quiet
docker compose up -d --build postgres minio airflow-webserver airflow-scheduler
```

Compose автоматически запустит зависимости Airflow, в том числе его базу метаданных и сервис инициализации.

**Airflow UI:** http://localhost:8080  
**MinIO Console:** http://localhost:9001  
**PostgreSQL:** `localhost:5433` при подключении с компьютера; `postgres:5432` из Docker-контейнеров.

### 4. Настройка Airflow Connection

В интерфейсе Airflow открыть **Admin → Connections** и создать подключение:

| Поле | Значение |
|---|---|
| Connection Id | `ecommerce_postgres` |
| Connection Type | `Postgres` |
| Host | `postgres` |
| Database / Schema | `ecommerce` |
| Login | `ecommerce` |
| Password | Значение `POSTGRES_PASSWORD` из `.env` |
| Port | `5432` |

Без этого подключения задача `create_staging_tables` не сможет выполнить DDL.

### 5. Запуск пайплайна

Открыть Airflow UI, найти DAG `ecommerce_pipeline` и запустить его через **Trigger DAG**. Убедиться, что все четыре задачи завершились успешно.

Проверка регистрации DAG из терминала:

```bash
docker compose exec airflow-scheduler airflow dags list
docker compose exec airflow-scheduler airflow tasks list ecommerce_pipeline
```

Проверка настроек dbt внутри Airflow:

```bash
docker compose exec airflow-scheduler bash -c "cd /opt/airflow/dbt && dbt debug"
```

### 6. Проверка таблиц в PostgreSQL

В DBeaver или другом SQL-клиенте выполнить:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('staging', 'dwh', 'dwh_marts')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;
```

Ожидается наличие 9 таблиц STAGING, 7 моделей DWH и 4 витрин MARTS. Данные в витринах можно проверить обычными `SELECT`-запросами.

## Контроль качества и ограничения

- В STAGING применяются ограничения PostgreSQL из DDL, включая первичные ключи для таблиц, в которых они определены.
- В dbt реализованы тесты уникальности и обязательности ключевых полей, проверки связей между моделями, а также отдельные SQL-тесты составных ключей.
- Загрузка настроена как **full refresh** для статичного источника. Инкрементальная обработка и CDC в текущий проект не входят.
- DAG запускается вручную, без расписания.
- Superset присутствует в Docker-инфраструктуре, но создание BI-дашбордов отложено и не входит в DAG.
- Повторный запуск и развёртывание с полностью пустого состояния стоит дополнительно протестировать перед утверждением полной воспроизводимости.


## Источник

Данные: [Olist — Brazilian E-Commerce Public Dataset (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
