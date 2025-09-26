#!/bin/bash
set -euo pipefail

QUEUE="my_queue"
TIMEOUT=10
INTERVAL=1

# Config
REDIS_HOST="${REDIS_HOST:-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"

S3_BUCKET="${S3_BUCKET:-test-bucket}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
AWS_REGION="${AWS_REGION:-us-east-1}"
S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-http://localstack:4566}"

echo "Running test consumer"

# Ensure redis-cli is installed in this container
if ! command -v redis-cli >/dev/null 2>&1; then
  echo "ERROR: redis-cli not found in container"
  exit 1
fi

# Ensure the S3 bucket exists
aws --endpoint-url "$S3_ENDPOINT_URL" s3 mb "s3://$S3_BUCKET" 2>/dev/null || true

elapsed=0
while [ $elapsed -lt $TIMEOUT ]; do
  MESSAGE=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" --raw RPOP "$QUEUE" || echo "")

  if [ -n "$MESSAGE" ]; then
    echo "Consumed message: $MESSAGE"

    FILE_PATH="/tmp/$MESSAGE.txt"
    echo "$MESSAGE" > "$FILE_PATH"

    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    AWS_DEFAULT_REGION=$AWS_REGION \
    aws --endpoint-url "$S3_ENDPOINT_URL" s3 cp "$FILE_PATH" "s3://$S3_BUCKET/$MESSAGE.txt"

    echo "Uploaded file to LocalStack S3: $S3_BUCKET/$MESSAGE.txt"
    exit 0
  fi

  sleep $INTERVAL
  elapsed=$((elapsed + INTERVAL))
done

echo "No message received"
exit 1
