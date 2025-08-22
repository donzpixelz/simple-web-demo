#!/bin/bash
set -e

# 1. Git workflow
echo "📦 Committing code changes..."
git add app/index.html app/css/main.css
git commit -m "Update site content"
git push origin main

# 2. Build & push Docker image
echo "🐳 Building and pushing Docker image..."
docker build -t chipsterz/simple-web-demo:latest .
docker push chipsterz/simple-web-demo:latest

# 3. Restart container on AWS
echo "🔄 Re-deploying container on AWS instance..."

# Get public IP from Terraform outputs
cd terraform
PUBLIC_IP=$(terraform output -raw public_ip)

# SSH into instance and restart the container
ssh -o StrictHostKeyChecking=no -i simple-web-demo-key.pem ec2-user@$PUBLIC_IP << 'EOF'
  set -e
  echo "Stopping old container..."
  sudo docker rm -f simple-web-demo || true

  echo "Pulling latest image..."
  sudo docker pull chipsterz/simple-web-demo:latest

  echo "Starting new container..."
  sudo docker run -d --name simple-web-demo -p 8080:80 --restart unless-stopped chipsterz/simple-web-demo:latest
EOF

cd ..

echo "✅ Deploy complete! Visit http://$PUBLIC_IP:8080"
