#!/bin/bash

set -e

# Step 1: Create necessary directories with correct permissions
sudo mkdir -p /data
sudo chmod 777 /data
echo "✅ Created /data directory with proper permissions"

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

# Step 3: Prompt user for Azure Subscription ID
read -p "Enter your Azure Subscription ID: " AZURE_SUBSCRIPTION_ID
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
    echo "⚠️ Subscription ID is required! Exiting..."
    exit 1
fi

# Step 4: Pull the latest agent repository from GitHub
echo "🔹 Cloning DiscoAPI repository..."
git clone https://github.com/RiadhJouini/DiscoAPI.git /opt/DiscoAPI

# Step 5: Build and Run the Docker container
cd /opt/DiscoAPI
docker build -t azure-discovery-agent .
docker run -d --restart always --name discovery-agent \
    -e CHATBOT_API_URL="http://127.0.0.1:5002/chat" \
    -e AZURE_SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID" \
    -v /data:/data \
    azure-discovery-agent

echo "✅ Agent successfully deployed and running!"
