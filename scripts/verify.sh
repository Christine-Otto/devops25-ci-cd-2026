
#!/bin/bash
set -e

echo "=== Verifying deployment ==="

for i in {1..10}; do
  if curl --fail --silent http://localhost:8000/health; then
    echo
    echo "Deployment verified successfully"
    exit 0
  fi

  echo "Waiting for application..."
  sleep 2
done

echo "Deployment verification failed"
exit 1