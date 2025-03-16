#!/bin/bash

set -e  # Stop on errors

# Step 1: Create necessary directories with correct permissions
sudo mkdir -p /data
sudo chown $(whoami) /data
echo "✅ Created necessary directories with proper permissions"

# Step 2: Install Docker if not installed
if ! command -v docker &> /dev/null
then
    echo "🔹 Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Step 3: Ask user for Subscription ID
read -p "Enter your Azure Subscription ID: " AZURE_SUBSCRIPTION_ID
export AZURE_SUBSCRIPTION_ID

# Step 4: Clone the repository (ensure permissions)
if [ -d "/opt/DiscoAPI" ]; then
    echo "⚠️ Directory /opt/DiscoAPI already exists. Removing it..."
    sudo rm -rf /opt/DiscoAPI
fi

echo "🔹 Cloning DiscoAPI repository..."
sudo git clone https://github.com/RiadhJouini/DiscoAPI.git /opt/DiscoAPI
sudo chown -R $(whoami) /opt/DiscoAPI

# Step 5: Build the Docker image
cd /opt/DiscoAPI
echo "🔹 Building Docker image..."
sudo docker build -t azure-discovery-agent .

# Step 6: Run the Docker container
echo "🔹 Running the Azure Discovery Agent..."
sudo docker run -d --restart always --name discovery-agent \
    -e CHATBOT_API_URL="http://127.0.0.1:5002/chat" \
    -e AZURE_SUBSCRIPTION_ID="$AZURE_SUBSCRIPTION_ID" \
    -v /data:/data \
    azure-discovery-agent

echo "✅ Agent successfully deployed and running!"
