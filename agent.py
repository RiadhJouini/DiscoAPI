import os
import json
import logging
import datetime
import requests
from azure.identity import DefaultAzureCredential
from azure.mgmt.resourcegraph import ResourceGraphClient

# Configuration Variables
CHATBOT_API_URL = os.getenv("CHATBOT_API_URL", "http://127.0.0.1:5002/chat")  # URL to send discovery results
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")  # The Azure subscription ID to scan
DISCOVERY_DIR = os.getenv("DISCOVERY_DIR", "/data")  # Directory where discovery data is stored

# Ensure discovery directory exists
os.makedirs(DISCOVERY_DIR, exist_ok=True)

# Logging Setup
LOG_FILE = os.path.join(DISCOVERY_DIR, "agent.log")
logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Azure Authentication
credential = DefaultAzureCredential()
resource_graph_client = ResourceGraphClient(credential)

def log_message(message):
    """Logs messages locally and prints them to console."""
    logging.info(message)
    print(message)

def discover_resources():
    """Scans Azure resources and saves structured discovery results."""
    try:
        log_message(f"🔍 Running discovery for subscription: {SUBSCRIPTION_ID}")

        # Azure Resource Graph Query
        query = """
        Resources 
        | project name, type, resourceGroup, location, properties
        """

        response = resource_graph_client.resources(
            query={"query": query, "subscriptions": [SUBSCRIPTION_ID]}
        )

        if not response.data:
            log_message("⚠️ No resources found in the subscription.")
            return

        categorized_resources = {
            "compute": [],
            "networking": [],
            "storage": [],
            "security": [],
            "databases": [],
            "other": []
        }

        for item in response.data:
            resource_info = {
                "name": item["name"],
                "resource_group": item["resourceGroup"],
                "location": item["location"],
                "properties": item.get("properties", {})
            }

            # Categorizing Resources
            if "compute" in item["type"].lower() or "managedclusters" in item["type"].lower():
                categorized_resources["compute"].append(resource_info)
            elif "network" in item["type"].lower() or "publicip" in item["type"].lower() or "loadbalancer" in item["type"].lower():
                categorized_resources["networking"].append(resource_info)
            elif "storage" in item["type"].lower() or "disk" in item["type"].lower():
                categorized_resources["storage"].append(resource_info)
            elif "security" in item["type"].lower() or "managedidentity" in item["type"].lower():
                categorized_resources["security"].append(resource_info)
            elif "sql" in item["type"].lower() or "database" in item["type"].lower():
                categorized_resources["databases"].append(resource_info)
            else:
                categorized_resources["other"].append(resource_info)

        # Save Discovery Data to File
        timestamp = datetime.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
        filename = f"discovery_{SUBSCRIPTION_ID}_{timestamp}.json"
        filepath = os.path.join(DISCOVERY_DIR, filename)

        with open(filepath, "w") as json_file:
            json.dump(categorized_resources, json_file, indent=2)

        log_message(f"✅ Discovery completed. Resources found: {len(response.data)}. File saved: {filepath}")

        # Send Discovery Data to Chatbot API
        send_to_chatbot(filepath)

    except Exception as e:
        log_message(f"❌ Discovery failed: {str(e)}")

def send_to_chatbot(filepath):
    """Sends the discovery results to the chatbot API."""
    try:
        with open(filepath, "r") as file:
            discovery_data = json.load(file)

        response = requests.post(CHATBOT_API_URL, json=discovery_data)

        if response.status_code == 200:
            log_message("✅ Discovery results successfully sent to chatbot.")
        else:
            log_message(f"⚠️ Failed to send data. Status Code: {response.status_code}")

    except Exception as e:
        log_message(f"❌ Error sending data to chatbot: {str(e)}")

if __name__ == "__main__":
    discover_resources()
