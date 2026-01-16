#!/bin/bash

# Utility functions and configuration for local environment scripts

# Detect shell
SHELL_NAME="${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}"

# Only set strict mode if not being sourced (when executed directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8050}"
ORGANIZATION_SERVICE_URL="${ORGANIZATION_SERVICE_URL:-http://localhost:8002/organization/api}"

# Helper function to print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Helper function to check for errors in API response
check_api_error() {
    local response=$1
    local http_code=$2
    
    # Check HTTP status code
    if [ "$http_code" -ge 400 ]; then
        return 1
    fi
    
    # Check for error code in JSON response
    local error_code=$(echo "$response" | jq -r '.code // empty' 2>/dev/null)
    if [ -n "$error_code" ] && [ "$error_code" != "null" ] && [ "$error_code" != "0" ]; then
        return 1
    fi
    
    return 0
}

# Helper function to display error details
show_error_details() {
    local response=$1
    local http_code=$2
    
    if [ "$http_code" -ge 400 ]; then
        print_error "HTTP Status: $http_code"
    fi
    
    local error_code=$(echo "$response" | jq -r '.code // empty' 2>/dev/null)
    local error_message=$(echo "$response" | jq -r '.message // empty' 2>/dev/null)
    
    if [ -n "$error_code" ] && [ "$error_code" != "null" ] && [ "$error_code" != "0" ]; then
        print_error "Error Code: $error_code"
    fi
    
    if [ -n "$error_message" ] && [ "$error_message" != "null" ]; then
        print_error "Error Message: $error_message"
    fi
}

# Helper function to query organization ID from database
get_learntowin_org_id() {
    local org_id=""
    local db_host="${L2W_POSTGRES_HOST:-localhost}"
    local db_port="${L2W_POSTGRES_PORT:-5432}"
    local db_user="postgres"
    local db_password="password"
    local db_name="organization"
    
    # Try to query via psql (local or docker)
    if command -v psql &> /dev/null; then
        # Try local psql connection
        org_id=$(PGPASSWORD="$db_password" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -t -c "SELECT id FROM organizations WHERE slug = 'learntowin' LIMIT 1;" 2>/dev/null | xargs 2>/dev/null)
    elif command -v docker &> /dev/null && docker ps | grep -q postgres; then
        # Try via docker exec
        local container_name=$(docker ps --format '{{.Names}}' | grep -i postgres | head -1)
        if [ -n "$container_name" ]; then
            org_id=$(docker exec "$container_name" psql -U "$db_user" -d "$db_name" -t -c "SELECT id FROM organizations WHERE slug = 'learntowin' LIMIT 1;" 2>/dev/null | xargs 2>/dev/null)
        fi
    fi
    
    # Clean up the org_id (remove whitespace)
    org_id=$(echo "$org_id" | tr -d '[:space:]')
    
    # Return empty if not found or invalid UUID format
    if [ -z "$org_id" ] || [ "$org_id" = "null" ] || ! echo "$org_id" | grep -qE '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'; then
        echo ""
    else
        echo "$org_id"
    fi
}

# Helper function to prompt for organization ID with database lookup
prompt_organization_id() {
    local var_value
    
    # Get the value of the variable using eval (works in both bash and zsh)
    eval "var_value=\${ORGANIZATION_ID:-}"
    
    if [ -z "$var_value" ]; then
        # Try to get from database
        local db_org_id=$(get_learntowin_org_id)
        
        if [ -n "$db_org_id" ]; then
            # Found in database, prompt user
            print_info "Found Learn To Win Organization in database: $db_org_id"
            local use_db_org=""
            if [ -n "${ZSH_VERSION:-}" ]; then
                read "use_db_org?Do you want to use the Learn To Win Organization? (y/n): "
            else
                read -p "Do you want to use the Learn To Win Organization? (y/n): " use_db_org
            fi
            
            if [ "$use_db_org" = "y" ] || [ "$use_db_org" = "Y" ] || [ "$use_db_org" = "yes" ] || [ "$use_db_org" = "Yes" ]; then
                export ORGANIZATION_ID="$db_org_id"
                print_success "Using organization ID: $ORGANIZATION_ID"
                return 0
            fi
        else
            print_warning "Unable to query Learn To Win Organization from DB"
        fi
        
        # Prompt normally if not using DB org or DB query failed
        if [ -n "${ZSH_VERSION:-}" ]; then
            read "var_value?Enter Organization ID: "
        else
            read -p "Enter Organization ID: " var_value
        fi
        export ORGANIZATION_ID="$var_value"
    fi
}

# Helper function to prompt for input if variable is not set
prompt_if_missing() {
    local var_name=$1
    local prompt_text=$2
    local var_value
    
    # Get the value of the variable using eval (works in both bash and zsh)
    eval "var_value=\${${var_name}:-}"
    
    if [ -z "$var_value" ]; then
        # Use zsh-compatible read syntax
        if [ -n "${ZSH_VERSION:-}" ]; then
            read "var_value?$prompt_text: "
        else
            read -p "$prompt_text: " var_value
        fi
        export "$var_name=$var_value"
    fi
}

# Helper function to extract JSON field value
extract_json_field() {
    local json=$1
    local field=$2
    echo "$json" | grep -o "\"$field\":\"[^\"]*\"" | cut -d'"' -f4 || echo ""
}

# Helper function to extract JSON array field
extract_json_array_field() {
    local json=$1
    local field=$2
    echo "$json" | grep -o "\"$field\":\[[^\]]*\]" | sed 's/.*\[\(.*\)\].*/\1/' | tr -d '"' || echo ""
}

# Reset all environment variables used by these functions
ltw_env_reset() {
    print_info "Resetting all environment variables..."
    
    unset EMAIL
    unset ORGANIZATION_ID
    unset USER_ID
    unset ROLE
    unset FIRST_NAME
    unset LAST_NAME
    unset IDP_TOKEN
    unset CONTEXT_TOKEN
    unset TASK_LIST_ID
    unset TASK_LIST_TITLE
    unset TASK_LIST_DESCRIPTION
    unset TASK_LIST_IS_AI_DRAFT
    
    # Reset configuration variables to defaults (optional - comment out if you want to keep custom values)
    # unset GATEWAY_URL
    # unset ORGANIZATION_SERVICE_URL
    
    print_success "Environment variables reset"
    print_info "The following variables have been unset:"
    echo "  EMAIL"
    echo "  ORGANIZATION_ID"
    echo "  USER_ID"
    echo "  ROLE"
    echo "  FIRST_NAME"
    echo "  LAST_NAME"
    echo "  IDP_TOKEN"
    echo "  CONTEXT_TOKEN"
    echo "  TASK_LIST_ID"
    echo "  TASK_LIST_TITLE"
    echo "  TASK_LIST_DESCRIPTION"
    echo "  TASK_LIST_IS_AI_DRAFT"
}
