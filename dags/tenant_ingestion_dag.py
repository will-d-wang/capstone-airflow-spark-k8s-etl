from datetime import datetime, timedelta
import os

from airflow import DAG
from airflow.decorators import task
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator

NAMESPACE = "ai-core-pipeline"

S3_ENDPOINT = os.environ.get("S3_ENDPOINT")
S3_BUCKET = os.environ.get("S3_BUCKET", "lake")

default_args = {
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="tenant_event_ingestion",
    start_date=datetime(2026, 3, 1),
    schedule="@daily",
    catchup=True,
    default_args=default_args,
    max_active_runs=1,
    tags=["ai-core", "ingestion"],
) as dag:

    @task
    def discover_tenants(run_date: str) -> list[str]:
        # For the mini-capstone, keep it simple: fixed tenants.
        # (You can later implement discovery by listing s3 prefixes.)
        return ["T1", "T2"]

    run_date = "{{ ds }}"
    tenants = discover_tenants(run_date)

    spark_transform = KubernetesPodOperator.partial(
        task_id="spark_transform",
        namespace=NAMESPACE,
        image="local/spark-job:dev",
        image_pull_policy="IfNotPresent",
        name="spark-transform",
        cmds=[],
        arguments=["--run_date", run_date],  # tenant_id added per mapped task
        env_vars={
            "S3_ENDPOINT": S3_ENDPOINT,
            "S3_BUCKET": S3_BUCKET,
        },
        get_logs=True,
        is_delete_operator_pod=True,
    ).expand(arguments=[["--run_date", run_date, "--tenant_id", t] for t in tenants])
