from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

PROJECT = "/opt/airflow/project"
VENV = "/home/airflow/dbt_venv/bin"

with DAG(
    dag_id="bixi_pipeline",
    description="Download the BIXI yearly ZIP files, load raw BIXI and weather files, then run dbt build",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["bixi"],
) as dag:
    download_bixi = BashOperator(
        task_id="download_bixi",
        bash_command=f"cd {PROJECT} && {VENV}/python ingestion/download_bixi.py",
        retries=2,
        retry_delay=timedelta(minutes=5),
        execution_timeout=timedelta(hours=1),
    )

    load_raw = BashOperator(
        task_id="load_raw",
        bash_command=f"cd {PROJECT} && {VENV}/python ingestion/load_raw.py",
        retries=1,
        retry_delay=timedelta(minutes=2),
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"cd {PROJECT}/dbt && {VENV}/dbt build --profiles-dir .",
        execution_timeout=timedelta(hours=2),
    )

    download_bixi >> load_raw >> dbt_build