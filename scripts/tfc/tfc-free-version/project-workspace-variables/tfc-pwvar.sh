#!/bin/bash

# ================================
# Configuration
# ================================
ORG_NAME="your-tfc-org"                         # Your org name
PROJECT_NAME="tfc-project-name"                 # Project name to use/create
WORKSPACE_NAME="tfc-workspace-name"             # Workspace name to create
API_TOKEN="$TFC_TOKEN"                          # Ensure this env var is set
API_URL="https://app.terraform.io/api/v2"

# ================================
# Headers
# ================================
HEADERS=(
  -H "Content-Type: application/vnd.api+json"
  -H "Authorization: Bearer ${API_TOKEN}"
)

# ================================
# Logging
# ================================
log() {
  echo -e "$@" >&2
}

# ================================
# Define Variables to Add
# Example values shown below for reference
# ================================

TF_VARS=(
  "region|us-east-1|false|terraform"
  "AWS_ACCESS_KEY_ID|abc123|true|env"
  "AWS_ACCESS_TEST|xyz789|false|env"
  "vpc_id|vpc-1234567890123456|false|terraform"
)

# ================================
# Function: Get or Create Project
# ================================
get_or_create_project_id() {
  log "🔍 Checking for project: $PROJECT_NAME"

  RESPONSE=$(curl -s "${API_URL}/organizations/${ORG_NAME}/projects?page[size]=100" "${HEADERS[@]}")
  PROJECT_ID=$(echo "$RESPONSE" | jq -r ".data[] | select(.attributes.name==\"$PROJECT_NAME\") | .id")

  if [[ -n "$PROJECT_ID" && "$PROJECT_ID" != "null" ]]; then
    log "✅ Found existing project '$PROJECT_NAME' with ID: $PROJECT_ID"
  else
    log "📁 Project '$PROJECT_NAME' not found. Creating it..."

    CREATE_RESPONSE=$(curl -s -X POST "${API_URL}/organizations/${ORG_NAME}/projects" \
      "${HEADERS[@]}" \
      -d @- <<EOF
{
  "data": {
    "type": "projects",
    "attributes": {
      "name": "$PROJECT_NAME"
    }
  }
}
EOF
    )

    PROJECT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.data.id')

    if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
      log "❌ Failed to create project."
      echo "$CREATE_RESPONSE" >&2
      exit 1
    fi

    log "✅ Successfully created project '$PROJECT_NAME' (ID: $PROJECT_ID)"
    sleep 3
  fi

  echo "$PROJECT_ID"
}

# ================================
# Main Script Execution Starts Here
# ================================

PROJECT_ID=$(get_or_create_project_id)

log "DEBUG: PROJECT_ID='$PROJECT_ID'"
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  log "❌ PROJECT_ID is empty or null after get_or_create_project_id. Aborting."
  exit 1
fi

# Check if workspace exists
log "🔍 Checking if workspace '$WORKSPACE_NAME' exists..."
WS_RESPONSE=$(curl -s "${API_URL}/organizations/${ORG_NAME}/workspaces/${WORKSPACE_NAME}" "${HEADERS[@]}")
WORKSPACE_ID=$(echo "$WS_RESPONSE" | jq -r '.data.id')

if [[ -n "$WORKSPACE_ID" && "$WORKSPACE_ID" != "null" ]]; then
  log "✅ Workspace '$WORKSPACE_NAME' already exists (ID: $WORKSPACE_ID)"
else
  # Create workspace with retry logic
  MAX_RETRIES=5
  RETRY_DELAY=3
  ATTEMPT=1

  log "⚙️ Creating workspace '$WORKSPACE_NAME' in project '$PROJECT_NAME'..."

  while [[ $ATTEMPT -le $MAX_RETRIES ]]; do
    log "🔁 Attempt $ATTEMPT of $MAX_RETRIES..."

    read -r -d '' PAYLOAD <<EOF
{
  "data": {
    "type": "workspaces",
    "attributes": {
      "name": "$WORKSPACE_NAME"
    },
    "relationships": {
      "project": {
        "data": {
          "id": "$PROJECT_ID",
          "type": "projects"
        }
      }
    }
  }
}
EOF

    CREATE_WS_RESPONSE=$(curl -s -X POST "${API_URL}/organizations/${ORG_NAME}/workspaces" \
      "${HEADERS[@]}" \
      -d "$PAYLOAD")

    WORKSPACE_ID=$(echo "$CREATE_WS_RESPONSE" | jq -r '.data.id')

    if [[ -n "$WORKSPACE_ID" && "$WORKSPACE_ID" != "null" ]]; then
      log "✅ Workspace '$WORKSPACE_NAME' created successfully (ID: $WORKSPACE_ID)"
      break
    else
      ERROR_MESSAGE=$(echo "$CREATE_WS_RESPONSE" | jq -r '.errors[0].detail // "Unknown error"')
      log "⚠️  Workspace creation failed: $ERROR_MESSAGE"

      if [[ $ATTEMPT -lt $MAX_RETRIES ]]; then
        log "⏳ Waiting $RETRY_DELAY seconds before retry..."
        sleep $RETRY_DELAY
      else
        log "❌ All retries failed. Could not create workspace."
        echo "$CREATE_WS_RESPONSE"
        exit 1
      fi
    fi

    ((ATTEMPT++))
  done
fi

# ================================
# Set Variables in Workspace
# ================================
log "📌 Adding variables directly to workspace: $WORKSPACE_NAME"

for var in "${TF_VARS[@]}"; do
  IFS='|' read -r key value sensitive category <<< "$var"
  log "📦 Creating variable: $key (category: $category, sensitive: $sensitive)"

  VAR_RESPONSE=$(curl -s -X POST "${API_URL}/workspaces/${WORKSPACE_ID}/vars" \
    "${HEADERS[@]}" \
    -d @- <<EOF
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "$key",
      "value": "$value",
      "category": "$category",
      "hcl": false,
      "sensitive": $sensitive
    }
  }
}
EOF
  )

  VAR_ID=$(echo "$VAR_RESPONSE" | jq -r '.data.id')

  if [[ -n "$VAR_ID" && "$VAR_ID" != "null" ]]; then
    log "✅ Variable '$key' created successfully."
  else
    log "⚠️ Failed to create variable '$key'."
    echo "$VAR_RESPONSE" >&2
  fi
done

log "🎉 Done!"
