#!/bin/bash

# === Config ===
API_TOKEN="$TFC_TOKEN"
ORG_NAME="your-tfc-org"  # Replace or parameterize as needed
API_URL="https://app.terraform.io/api/v2"

# === Headers ===
HEADERS=(
  -H "Content-Type: application/vnd.api+json"
  -H "Authorization: Bearer ${API_TOKEN}"
)

# === Step 1: Check if token is set ===
if [[ -z "$API_TOKEN" ]]; then
  echo "❌ TFC_TOKEN environment variable is not set."
  exit 1
fi

# === Step 2: Check organization access ===
echo "🔍 Verifying access to organization '$ORG_NAME'..."
ORG_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/organizations/${ORG_NAME}" "${HEADERS[@]}")

if [[ "$ORG_RESPONSE" -ne 200 ]]; then
  echo "❌ Cannot access organization '$ORG_NAME'. HTTP Status: $ORG_RESPONSE"
  exit 1
fi
echo "✅ Organization access confirmed."

# === Step 3: Check projects API access ===
echo "🔍 Checking access to Projects API..."
PROJ_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/organizations/${ORG_NAME}/projects" "${HEADERS[@]}")

if [[ "$PROJ_RESPONSE" -ne 200 ]]; then
  echo "❌ Cannot access Projects API. Check token permissions. HTTP Status: $PROJ_RESPONSE"
  exit 1
fi
echo "✅ Projects API access confirmed."

# === Step 4: Check workspaces API access ===
echo "🔍 Checking access to Workspaces API..."
WS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/organizations/${ORG_NAME}/workspaces" "${HEADERS[@]}")

if [[ "$WS_RESPONSE" -ne 200 ]]; then
  echo "❌ Cannot access Workspaces API. Check token permissions. HTTP Status: $WS_RESPONSE"
  exit 1
fi
echo "✅ Workspaces API access confirmed."

echo "🎯 Token is valid and has sufficient access for project + workspace script."
