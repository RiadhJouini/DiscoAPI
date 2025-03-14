from fastapi import FastAPI, HTTPException
from azure.identity import DefaultAzureCredential
from azure.mgmt.resourcegraph import ResourceGraphClient
import os
import json
import datetime
import requests

app = FastAPI()

# Environment Variables
CHATBOT_API_URL = os.getenv("CHATBOT_API_URL", "http://127.0.0.1:5002/chat")
SUBSCRIPTION_ID = os.getenv("AZURE_SUBSCRIPTION_ID")
DISCOVERY_DIR = os.getenv("DISCOVERY_DIR", "/data")

# Ensure the directory exists
os.makedirs(DISCOVERY_DIR, exist_ok=True)

# Azure Authentication
credential = DefaultAzureCredential()
resource_graph_client = ResourceGraphClient(credential)

@app.get("/discover")
def discover_resources():
    """Discovers all resources in the Azure subscription and stores them locally."""
    if not SUBSCRIPTION_ID:
        raise HTTPException(status_code=400, detail="AZURE_SUBSCRIPTION_ID is not set.")
    
    try:
        query = "Resources | project name, type, resourceGroup, location, properties"
        response = resource_graph_client.resources(query={"query": query, "subscriptions": [SUBSCRIPTION_ID]})

        discovery_data = {
            "compute": [],
            "networking": [],
            "storage": [],
            "security": [],
            "other": []
        }

        for item in response.data:
            resource_info = {
                "name": item["name"],
                "resource_group": item["resourceGroup"],
                "location": item["location"],
                "properties": item.get("properties", {})
            }
            
            # Categorization
            if "compute" in item["type"].lower():
                discovery_data["compute"].append(resource_info)
            elif "network" in item["type"].lower():
                discovery_data["networking"].append(resource_info)
            elif "storage" in item["type"].lower():
                discovery_data["storage"].append(resource_info)
            elif "security" in item["type"].lower():
                discovery_data["security"].append(resource_info)
            else:
                discovery_data["other"].append(resource_info)

        # Save JSON file locally
        timestamp = datetime.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
        filename = f"discovery_{SUBSCRIPTION_ID}_{timestamp}.json"
        filepath = os.path.join(DISCOVERY_DIR, filename)
        with open(filepath, "w") as json_file:
            json.dump(discovery_data, json_file, indent=2)
        
        # Send discovery data to chatbot API
        try:
            requests.post(CHATBOT_API_URL, json={"subscription_id": SUBSCRIPTION_ID, "data": discovery_data})
        except Exception as e:
            print(f"⚠️ Failed to send data to chatbot API: {e}")
        
        return {"message": "Discovery completed", "file_path": filepath}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=json.dumps({"error": str(e)}))
