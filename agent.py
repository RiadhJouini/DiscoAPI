import os
import json
import logging
import requests
import datetime
from azure.identity import DefaultAzureCredential
from azure.mgmt.resourcegraph import ResourceGraphClient

DATA_DIR = os.getenv("DISCOVERY_DIR", "/data")
LOG_FILE = os.path.join(DATA_DIR, "agent.log")

if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR, exist_ok=True)

try:
    os.chmod(DATA_DIR, 0o755)  # Owner can read/write, others can read
    if os.path.exists(LOG_FILE):
        os.chmod(LOG_FILE, 0o644)  # Log file: owner read/write, others read-only
except Exception as e:
    print(f"⚠️ Warning: Could not update permissions for {DATA_DIR} - {e}")

logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

credential = DefaultAzureCredential()
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")

if not subscription_id:
    logging.error("❌ AZURE_SUBSCRIPTION_ID is not set. Please provide a valid subscription.")
    raise ValueError("AZURE_SUBSCRIPTION_ID is required!")

resource_graph_client = ResourceGraphClient(credential)

def run_discovery():
    """Perform Azure resource discovery and send results to chatbot API."""
    try:
        timestamp = datetime.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
        output_file = os.path.join(DATA_DIR, f"discovery_{subscription_id}_{timestamp}.json")

        logging.info(f"🔍 Starting discovery for subscription {subscription_id}...")

        query = "Resources | project name, type, resourceGroup, location, properties"
        response = resource_graph_client.resources(query={"query": query, "subscriptions": [subscription_id]})

        categorized_resources = {"compute": [], "networking": [], "storage": [], "security": [], "other": []}
        for item in response.data:
            resource_info = {
                "name": item["name"],
                "resource_group": item["resourceGroup"],
                "location": item["location"],
                "properties": item.get("properties", {})
            }
            if "compute" in item["type"].lower():
                categorized_resources["compute"].append(resource_info)
            elif "network" in item["type"].lower():
                categorized_resources["networking"].append(resource_info)
            elif "storage" in item["type"].lower():
                categorized_resources["storage"].append(resource_info)
            elif "security" in item["type"].lower():
                categorized_resources["security"].append(resource_info)
            else:
                categorized_resources["other"].append(resource_info)

        with open(output_file, "w") as json_file:
            json.dump(categorized_resources, json_file, indent=2)

        logging.info(f"✅ Discovery completed. Resources found: {len(response.data)}. File saved: {output_file}")

        chatbot_api_url = os.getenv("CHATBOT_API_URL", "http://127.0.0.1:5002/chat/analyze")
        send_data_to_chatbot(categorized_resources, chatbot_api_url)

    except Exception as e:
        logging.error(f"❌ Discovery failed: {e}")

def send_data_to_chatbot(discovery_data, api_url):
    """Send discovery data to the chatbot API for analysis."""
    try:
        response = requests.post(api_url, json=discovery_data)
        if response.status_code == 200:
            logging.info("📤 Discovery data successfully sent to chatbot API.")
        else:
            logging.error(f"⚠️ Failed to send data. Status: {response.status_code}, Response: {response.text}")
    except Exception as e:
        logging.error(f"⚠️ Error sending data to chatbot API: {e}")

if __name__ == "__main__":
    run_discovery()
