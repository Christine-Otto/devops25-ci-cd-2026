
#!/bin/bash
set -e

echo "=== Starting local deployment ==="
echo "Building Docker image..."
docker build -t devops25-app .

echo "Removing previous container if it exists..."
docker rm -f devops25-app 2>/dev/null || true

echo "Starting application..."
docker run -d --name devops25-app -p 8000:8000 devops25-app

echo "=== Deployment started ==="