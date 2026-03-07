FROM python:3.11-slim

WORKDIR /app

COPY requirements/spark.txt /app/requirements/spark.txt
RUN pip install --no-cache-dir -r /app/requirements/spark.txt
COPY src/ /app/src/

ENV PYTHONPATH=/app/src

ENTRYPOINT ["python", "-m", "pipeline.jobs.spark_transform"]
