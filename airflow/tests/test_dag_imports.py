import importlib.util
from pathlib import Path

import pytest


def test_dag_modules_import(dags_dir: Path) -> None:
    airflow = pytest.importorskip("airflow")
    if not hasattr(airflow, "DAG"):
        pytest.skip("Apache Airflow is not fully installed in this environment")
    for dag_file in ("daily_ingest.py", "daily_feature_build.py"):
        spec = importlib.util.spec_from_file_location(dag_file, dags_dir / dag_file)
        assert spec and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
