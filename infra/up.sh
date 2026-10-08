#!/usr/bin/env bash
# поднимает silo, postgres, lakekeeper и trino
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG_URL='postgresql://postgres:postgres@host.docker.internal:5432/postgres'
ENC_KEY='This-is-NOT-Secure!'

# хранилище (silo - форк minio)
docker run -d --name p1-minio \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin \
  -v p1-minio-data:/data \
  pgsty/silo:latest server /data --console-address ":9001"

until curl -sf http://localhost:9000/minio/health/live >/dev/null; do sleep 1; done
docker run --rm --entrypoint /bin/sh --add-host host.docker.internal:host-gateway \
  pgsty/mc:latest -c "mc alias set m http://host.docker.internal:9000 minioadmin minioadmin \
    && mc mb --ignore-existing m/bronze m/silver m/gold"

# postgres для lakekeeper
docker run -d --name p1-pg \
  -e POSTGRES_PASSWORD=postgres -p 5432:5432 \
  -v p1-pg-data:/var/lib/postgresql/data \
  postgres:17
until docker exec p1-pg pg_isready -q; do sleep 1; done
sleep 2

# lakekeeper
docker run --rm \
  -e "LAKEKEEPER__PG_ENCRYPTION_KEY=$ENC_KEY" \
  -e "LAKEKEEPER__PG_DATABASE_URL_READ=$PG_URL" \
  -e "LAKEKEEPER__PG_DATABASE_URL_WRITE=$PG_URL" \
  quay.io/lakekeeper/catalog:latest-main migrate
docker run -d --name p1-lakekeeper \
  -e "LAKEKEEPER__PG_ENCRYPTION_KEY=$ENC_KEY" \
  -e "LAKEKEEPER__PG_DATABASE_URL_READ=$PG_URL" \
  -e "LAKEKEEPER__PG_DATABASE_URL_WRITE=$PG_URL" \
  -p 8181:8181 \
  quay.io/lakekeeper/catalog:latest-main serve
until curl -sf http://localhost:8181/health >/dev/null; do sleep 1; done

# принять ToU и создать warehouse на каждый слой
curl -s -o /dev/null -X POST http://localhost:8181/management/v1/bootstrap \
  -H 'Content-Type: application/json' -d '{"accept-terms-of-use": true}' || true
for layer in bronze silver gold; do
  curl -s -X POST http://localhost:8181/management/v1/warehouse \
    -H 'Content-Type: application/json' -d @- <<EOF
{
  "warehouse-name": "$layer",
  "project-id": "00000000-0000-0000-0000-000000000000",
  "storage-profile": {
    "type": "s3", "bucket": "$layer", "key-prefix": "",
    "endpoint": "http://host.docker.internal:9000", "region": "us-east-1",
    "path-style-access": true, "flavor": "s3-compat", "sts-enabled": false
  },
  "storage-credential": {
    "type": "s3", "credential-type": "access-key",
    "access-key-id": "minioadmin", "secret-access-key": "minioadmin"
  }
}
EOF
  echo
done

# trino (2 ГБ, чтобы не съел всю память на ноуте)
docker run -d --name p1-trino \
  --memory 2g \
  -p 8080:8080 \
  -v "$ROOT/infra/catalog:/etc/trino/catalog" \
  trinodb/trino:476
until [ "$(docker inspect -f '{{.State.Health.Status}}' p1-trino)" = healthy ]; do sleep 2; done

docker exec p1-trino trino --execute "SHOW CATALOGS"
