#!/bin/bash

# Ensure necessary environment variables are set
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
    echo "❌ ERROR: AZURE_SUBSCRIPTION_ID is not set."
    exit 1
fi

if [ -z "$CHATBOT_API_URL" ]; then
    echo "❌ ERROR: CHATBOT_API_URL is not set."
    exit 1
fi

# Run the agent
echo "🚀 Starting Azure Discovery Agent..."
python /app/agent.py
