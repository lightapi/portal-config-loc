#!/bin/sh
# wait-for-it.sh

HOST=$1
PORT=$2
TIMEOUT=${3:-30}  # Default timeout is 15 seconds

connected=0
for i in $(seq 1 $TIMEOUT); do
  echo "Checking connection to ${HOST}:${PORT}..."
  nc -z "$HOST" "$PORT" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    connected=1
    break
  fi
  sleep 1
done

if [ $connected -eq 1 ]; then
  echo "${HOST}:${PORT} is available."
  shift 3 # Remove host, port, and timeout from arguments
  exec "$@"
else
  echo "Timeout waiting for ${HOST}:${PORT}."
  exit 1
fi
