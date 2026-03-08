FROM apache/airflow:3.1.7 AS deps

USER airflow
COPY airflow/requirements.txt /opt/airflow/requirements.txt
RUN pip install --no-cache-dir -r /opt/airflow/requirements.txt

FROM deps AS tests
WORKDIR /opt/airflow
COPY dags/ /opt/airflow/dags/
COPY jobs/ /opt/airflow/jobs/
COPY tests/ /opt/airflow/tests/
RUN pip install --no-cache-dir pytest
ENV PYTHONPATH=/opt/airflow

FROM deps AS runtime
