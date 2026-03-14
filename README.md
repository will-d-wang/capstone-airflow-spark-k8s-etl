# Capstone Airflow Spark K8s ETL

This project demonstrates a daily ETL + feature build pipeline using Airflow orchestration, PySpark transforms, and Kubernetes task isolation.

## Layout

- `airflow/` Airflow orchestration code, DAG tests, and Helm configuration.
- `jobs/` PySpark job code and job-level tests.
- `docker/` Container images for Airflow and Spark job runtimes.
- `infra/` Kubernetes and Terraform infrastructure definitions.
- `scripts/` Helper scripts for local setup, builds, deployment, and testing.

## Docs

Refer to the docs for setup and operations:

- Architecture diagrams: [docs/architecture.md](docs/architecture.md)
- Local development: [docs/setup.md](docs/setup.md)
- Run and deploy: [docs/run.md](docs/run.md)
- Tests: [docs/tests.md](docs/tests.md)
- Debugging and operations: [docs/debugging.md](docs/debugging.md)
