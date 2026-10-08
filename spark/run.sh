#!/usr/bin/env bash
# spark-sql по bronze, нужны p1-minio и p1-lakekeeper
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
V=1.7.1
mkdir -p "$DIR/jars"
for jar in "iceberg-spark-runtime-3.5_2.12" "iceberg-aws-bundle"; do
  [ -f "$DIR/jars/$jar-$V.jar" ] || curl -fsSL -o "$DIR/jars/$jar-$V.jar" \
    "https://repo1.maven.org/maven2/org/apache/iceberg/$jar/$V/$jar-$V.jar"
done

docker run --rm --name p1-spark \
  --memory 2g \
  --add-host host.docker.internal:host-gateway \
  -v "$DIR/spark-defaults.conf:/opt/spark/conf/spark-defaults.conf:ro" \
  -v "$DIR/jars:/opt/spark/iceberg-jars:ro" \
  -v "$DIR:/opt/spark/work:ro" \
  apache/spark:3.5.3 \
  /opt/spark/bin/spark-sql --conf spark.ui.enabled=false -f /opt/spark/work/bronze_demo.sql
