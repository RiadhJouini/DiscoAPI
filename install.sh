#!/bin/bash

set -e  # Stop script on any error

# Step 1: Create necessary directories in the user's home (Avoids permission issues)
DATA_DIR="$HOME/data"
mkdir -p "$DATA_DIR"
echo "✅ Created $DATA_DIR directory"

# Step 2: Install required dependencies (Docker & Git)
echo "🔹 Checking for required dependencies..."

# Install Git if not installed
if ! command -v git &> /dev/null
then
    echo "🔹 Installing Git..."
    sudo apt update && sudo apt install -y git
    echo "✅ Git installed successfully"
else
    echo "✅ Git is already installed"
fi

# Install Docker if not installed
if ! command -v docker &> /dev/null
then
    echo "🔹 Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker is already installed"
fi

# Step 3: Clone or update the DiscoAPI repository
INSTALL_DIR="/opt/DiscoAPI"

if [ -d "$INSTALL_DIR" ]; then
    echo "🔹 Repository already exists. Updating..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo "🔹 Cloning DiscoAPI repository..."
    sudo git clone https://github.com/RiadhJouini/DiscoAPI.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Step 4: Build and run the Docker container
echo "🔹 Building the Azure Discovery Agent container..."
sudo docker build -t azure-discovery-agent .

echo "🔹 Running the agent container..."
sudo docker run -d --restart always --name discovery-agent \
    -e CHATBOT_API_URL="http://127.0.0.1:5002/chat" \
    -e AZURE_SUBSCRIPTION_ID="25204208-7b7c-454e-bead-bc349832fed9" \
    -v "$DATA_DIR:/data" \
    azure-discovery-agent

echo "✅ Agent successfully deployed and running!"
