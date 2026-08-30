#!/bin/bash
set -e

# Real values live in .env (gitignored, next to this script) — see
# .env.example for what's needed. Kept out of the script itself so this
# file can be committed without leaking your AWS account ID / server IP.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID in .env}"
: "${AWS_REGION:?Set AWS_REGION in .env}"
: "${EC2_PUBLIC_IP:?Set EC2_PUBLIC_IP in .env}"

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "Building backend image..."
docker build --platform linux/amd64 -t taskpilot-backend "$SCRIPT_DIR/../taskpilot-backend"

echo "Building frontend image..."
# VITE_API_URL is baked in at BUILD time — this must be the address the
# BROWSER will use, i.e. your EC2 instance's public IP, not "localhost"
# and not the internal ECR/RDS hostname.
docker build --platform linux/amd64 -t taskpilot-frontend \
  --build-arg VITE_API_URL="http://${EC2_PUBLIC_IP}:8000" \
  "$SCRIPT_DIR/../taskpilot-frontend"

echo "Tagging images for ECR..."
docker tag taskpilot-backend:latest "${ECR_REGISTRY}/taskpilot-backend:latest"
docker tag taskpilot-frontend:latest "${ECR_REGISTRY}/taskpilot-frontend:latest"

echo "Pushing to ECR..."
docker push "${ECR_REGISTRY}/taskpilot-backend:latest"
docker push "${ECR_REGISTRY}/taskpilot-frontend:latest"

echo "Done. Images pushed to:"
echo "  ${ECR_REGISTRY}/taskpilot-backend:latest"
echo "  ${ECR_REGISTRY}/taskpilot-frontend:latest"
