from pyspark.sql.types import StructType, StructField, StringType, MapType

RAW_SCHEMA = StructType([
    StructField("tenant_id", StringType(), nullable=False),
    StructField("event_id", StringType(), nullable=False),
    StructField("event_ts", StringType(), nullable=False),
    StructField("event_type", StringType(), nullable=False),
    StructField("payload", MapType(StringType(), StringType()), nullable=True),
])
