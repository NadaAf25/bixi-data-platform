from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

PROJECT = "/opt/airflow/project"
VENV = "/home/airflow/dbt_venv/bin"

with DAG(
    dag_id="bixi_pipeline",
    description="Load raw BIXI and weather files, then run dbt build",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["bixi"],
) as dag:
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

    load_raw >> dbt_build