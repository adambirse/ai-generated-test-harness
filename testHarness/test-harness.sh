#!/bin/bash
set -euo pipefail

QUEUE="my_queue"

REDIS_HOST="${REDIS_HOST:-redis}"
REDIS_PORT="${REDIS_PORT:-6379}"

S3_BUCKET="${S3_BUCKET:-test-bucket}"
S3_ENDPOINT_URL="${S3_ENDPOINT_URL:-http://localstack:4566}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"

TIMEOUT=10
INTERVAL=1

# Generate a random message name
MESSAGE="test-message-$(date +%s)-$RANDOM"

echo "Generated random message: $MESSAGE"

# 0. Clear any existing messages in the queue
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DEL "$QUEUE" > /dev/null

# 1. Add the message to the queue
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" LPUSH "$QUEUE" "$MESSAGE" > /dev/null

echo "Message '$MESSAGE' pushed to Redis, waiting for consumer..."

# 2. Wait up to TIMEOUT seconds for the message to be removed by the consumer
elapsed=0
while [ $elapsed -lt $TIMEOUT ]; do
  LENGTH=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" LLEN "$QUEUE")
  if [ "$LENGTH" -eq 0 ]; then
    echo "Message consumed from Redis"
    break
  fi
  sleep $INTERVAL
  elapsed=$((elapsed + INTERVAL))
done

if [ "$LENGTH" -ne 0 ]; then
  echo "Test Failure: message not consumed from Redis"
  exit 1
fi

# 3. Wait until file exists in S3 (LocalStack)
elapsed=0
FILE_KEY="$MESSAGE.txt"
while [ $elapsed -lt $TIMEOUT ]; do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$AWS_ACCESS_KEY_ID:$AWS_SECRET_ACCESS_KEY" \
    "$S3_ENDPOINT_URL/$S3_BUCKET/$FILE_KEY")

  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "File exists in S3: $S3_BUCKET/$FILE_KEY"
    echo "Test Success"
    exit 0
  fi

  sleep $INTERVAL
  elapsed=$((elapsed + INTERVAL))
done

# If we reach here, the file was never found
echo "Test Failure: file not found in S3"
exit 1
