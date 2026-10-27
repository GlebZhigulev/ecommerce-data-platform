FROM quay.io/jupyter/scipy-notebook:2026-07-28

USER ${NB_UID}

RUN pip install --no-cache-dir \
    boto3 \
    kagglehub \
    psycopg2-binary \
    sqlalchemy \
    pyarrow

WORKDIR /home/jovyan/work
