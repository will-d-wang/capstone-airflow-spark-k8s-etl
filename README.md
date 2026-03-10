# Capstone Airflow Spark K8s ETL

This project demonstrates a daily ETL + feature build pipeline using Airflow orchestration, PySpark transforms, and Kubernetes task isolation.

## Layout

- `airflow/` Airflow orchestration code, DAG tests, and Helm configuration.
- `jobs/` PySpark job code and job-level tests.
- `docker/` Container images for Airflow and Spark job runtimes.
- `infra/` Kubernetes and Terraform infrastructure definitions.
- `scripts/` Helper scripts for local setup, builds, deployment, and testing.

## Prerequisites

- Docker
- Minikube
- kubectl
- Helm 3
- Terraform
- uv
- Python 3.11+

## Local Dev (uv)

Use a single local environment with both runtime profiles installed:

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -e ".[airflow,jobs-spark,dev]"
```

Run tests and tooling from the same environment:

```bash
# Activate once per shell
source .venv/bin/activate

# Airflow tests
pytest airflow/tests

# Spark jobs tests
pytest jobs/tests

# Lint and type-check
ruff check .
mypy
```

## Run

1. Start Minikube profile for this project:

```bash
scripts/00_minikube_up.sh
# Optional sanity check (explicit profile):
minikube status -p ai-core-etl
```

1. Build runtime images into Minikube Docker daemon:

```bash
scripts/build_images.sh
```

This builds:

- `local/spark-job:dev`
- `local/airflow-custom:dev` (installs Airflow dependencies from `pyproject.toml` and runs unit tests in a Docker build stage)

1. Set credentials via environment variables (recommended).  
For demo usage, defaults exist in scripts, but avoid committing real secrets.

```bash
export POSTGRES_USER='airflow'
export POSTGRES_PASSWORD='change-me-postgres'
export POSTGRES_DB='airflow'
export MINIO_ROOT_USER='minioadmin'
export MINIO_ROOT_PASSWORD='change-me-minio'
export AIRFLOW_ADMIN_USERNAME='admin'
export AIRFLOW_ADMIN_PASSWORD='change-me-airflow-admin'
export AIRFLOW_ADMIN_EMAIL='admin@example.com'
export AIRFLOW_ADMIN_FIRST_NAME='Admin'
export AIRFLOW_ADMIN_LAST_NAME='User'
```

1. Deploy the full platform with Terraform (consolidated steps 01-04):

```bash
scripts/01_deploy_infra.sh
```

`scripts/01_deploy_infra.sh` runs a single Terraform apply from `infra/terraform` and:

- `pipeline-secrets` from `POSTGRES_*` and `MINIO_*` env vars
- `airflow-metadata-secret` from DB env vars (used by Airflow as metadata connection)
- Deploys Postgres + MinIO
- Installs Airflow via Helm
- Optionally runs `scripts/bootstrap_env.sh` after apply

`scripts/bootstrap_env.sh`:

- Waits for Postgres, MinIO, and Airflow scheduler rollout
- Runs the seed-data job
- Configures local access (updates `/etc/hosts` and verifies MinIO API health)

Set `SKIP_BOOTSTRAP=true` to run Terraform apply without bootstrap steps.

Before running, set your DAG git repo in `airflow/helm-values.yaml`:

- Replace `https://github.com/<YOUR_GITHUB>/<YOUR_REPO>.git`.

Then open:

- Airflow: `http://airflow.local` (`$AIRFLOW_ADMIN_USERNAME` / `$AIRFLOW_ADMIN_PASSWORD`)
- MinIO console: `http://minio-console.local` (`$MINIO_ROOT_USER` / `$MINIO_ROOT_PASSWORD`)

## Trigger DAGs

```bash
scripts/02_trigger_run.sh trigger 2026-03-06 daily_ingest
scripts/02_trigger_run.sh trigger 2026-03-06 daily_feature_build
scripts/02_trigger_run.sh backfill 2026-03-06 2026-03-07 daily_ingest
```

## Tests

```bash
scripts/run_unit_tests.sh local
# or:
scripts/run_unit_tests.sh docker
```

## Debugging

```bash
scripts/02_trigger_run.sh pods
scripts/02_trigger_run.sh logs
kubectl -n ai-core-pipeline logs <spark-pod-name>
kubectl -n ai-core-pipeline describe pod <spark-pod-name>
```
