#!/bin/bash

set -e

# Step 1: Create necessary directories
mkdir -p /data
echo "✅ Created /data directory"

# Step 2: Install Docker if not installed
if ! command -v docker &> /dev/null
then
    echo "🔹 Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Step 3: Pull the latest agent repository from GitHub
echo "🔹 Cloning DiscoAPI repository..."
git clone https://github.com/RiadhJouini/DiscoAPI.git /opt/DiscoAPI

# Step 4: Build and Run the Docker container
cd /opt/DiscoAPI
docker build -t azure-discovery-agent .
docker run -d --restart always --name discovery-agent \
    -e CHATBOT_API_URL="http://127.0.0.1:5002/chat" \
    -e AZURE_SUBSCRIPTION_ID="your-subscription-id" \
    -v /data:/data \
    azure-discovery-agent

echo "✅ Agent successfully deployed and running!"

