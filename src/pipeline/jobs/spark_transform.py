import os
import argparse
from pyspark.sql import SparkSession, functions as F, Window
from pipeline.libs.schema import RAW_SCHEMA


def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--run_date", required=True)  # YYYY-MM-DD
    p.add_argument("--tenant_id", default=None)
    p.add_argument("--s3_endpoint", default=os.environ.get("S3_ENDPOINT"))
    p.add_argument("--bucket", default=os.environ.get("S3_BUCKET", "lake"))
    return p.parse_args()


def main():
    args = parse_args()
    spark = (
        SparkSession.builder
        .appName("tenant-event-transform")
        .config("spark.sql.shuffle.partitions", "8")
        .getOrCreate()
    )

    # MinIO (S3A) settings - for local demo
    hconf = spark.sparkContext._jsc.hadoopConfiguration()
    hconf.set("fs.s3a.endpoint", args.s3_endpoint.replace("http://", "").replace("https://", ""))
    hconf.set("fs.s3a.path.style.access", "true")
    hconf.set("fs.s3a.connection.ssl.enabled", "false")
    hconf.set("fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
    hconf.set("fs.s3a.aws.credentials.provider", "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider")
    hconf.set("fs.s3a.access.key", os.environ["AWS_ACCESS_KEY_ID"])
    hconf.set("fs.s3a.secret.key", os.environ["AWS_SECRET_ACCESS_KEY"])

    dt = args.run_date
    tenant_filter = f"/tenant_id={args.tenant_id}" if args.tenant_id else ""
    raw_path = f"s3a://{args.bucket}/raw/dt={dt}{tenant_filter}/*.json"
    out_path = f"s3a://{args.bucket}/curated/events/dt={dt}/"

    df = spark.read.schema(RAW_SCHEMA).json(raw_path)

    # Normalize + dt partition
    df = (
        df.withColumn("event_ts_ts", F.to_timestamp("event_ts"))
        .withColumn("dt", F.to_date("event_ts_ts"))
        .withColumn("payload_json", F.to_json("payload"))
        .drop("payload")
    )

    # Dedup keep latest by tenant_id+event_id
    w = Window.partitionBy("tenant_id", "event_id").orderBy(F.col("event_ts_ts").desc())
    df = (
        df.withColumn("rn", F.row_number().over(w))
        .filter(F.col("rn") == 1)
        .drop("rn")
    )

    # Write partitioned by tenant_id (dt already fixed in path)
    # Idempotent for the partition: overwrite that date's output
    (
        df.repartition("tenant_id")
        .write.mode("overwrite")
        .partitionBy("tenant_id")
        .parquet(out_path)
    )

    spark.stop()


if __name__ == "__main__":
    main()
