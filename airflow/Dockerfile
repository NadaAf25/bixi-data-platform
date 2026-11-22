FROM apache/airflow:3.2.2

RUN python -m venv /home/airflow/dbt_venv \
 && /home/airflow/dbt_venv/bin/pip install --no-cache-dir \
    dbt-core==1.12.7 dbt-postgres==1.11.0 psycopg2-binary