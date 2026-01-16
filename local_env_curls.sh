#!/bin/bash

# Local Environment cURL Helper Script
# Source this file to add functions to your shell session:
#   source local_env_curls.sh
# Or: . local_env_curls.sh

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

# Create User
# Requirements: ORGANIZATION_ID, EMAIL, ROLE
create_user() {
    print_info "Creating user..."
    
    prompt_if_missing ORGANIZATION_ID "Enter Organization ID"
    prompt_if_missing EMAIL "Enter user email"
    prompt_if_missing ROLE "Enter role (e.g., ROLE_ADMIN, ROLE_SUPER_ADMIN)"
    
    local first_name="${FIRST_NAME:-feed}"
    local last_name="${LAST_NAME:-sensor}"
    
    print_info "Creating user: $EMAIL with role: $ROLE in org: $ORGANIZATION_ID"
    
    local http_code
    local response=$(curl -s -w "\n%{http_code}" --location "$ORGANIZATION_SERVICE_URL/users" \
        --header "x-user-data: {\"id\":\"$ORGANIZATION_ID\",\"orgId\":\"$ORGANIZATION_ID\",\"roles\":[\"ROLE_SUPER_ADMIN\"]}" \
        --header 'Content-Type: application/json' \
        --data-raw "{
            \"email\": \"$EMAIL\",
            \"first_name\": \"$first_name\",
            \"last_name\": \"$last_name\",
            \"roles\": [\"$ROLE\"]
        }")
    
    # Extract HTTP code (last line) and response body (everything else)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check for errors
    if ! check_api_error "$response" "$http_code"; then
        print_error "Failed to create user"
        show_error_details "$response" "$http_code"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
    
    print_success "User created successfully"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    
    # Extract user ID if available
    local user_id=$(echo "$response" | jq -r '.id // empty' 2>/dev/null)
    if [ -n "$user_id" ] && [ "$user_id" != "null" ]; then
        export USER_ID="$user_id"
        print_info "User ID stored in USER_ID: $USER_ID"
    fi
}

# Get Organizations
# Requirements: EMAIL (with URL encoding)
get_organizations() {
    print_info "Getting organizations..."
    
    prompt_if_missing EMAIL "Enter user email"
    
    print_info "Fetching organizations for: $EMAIL"
    
    local http_code
    local response=$(curl -s -w "\n%{http_code}" -G "$GATEWAY_URL/v1/organizations" \
        --data-urlencode "user_email=$EMAIL")
    
    # Extract HTTP code (last line) and response body (everything else)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check for errors
    if ! check_api_error "$response" "$http_code"; then
        print_error "Failed to get organizations"
        show_error_details "$response" "$http_code"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
    
    print_success "Organizations retrieved successfully"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    
    # Extract first organization ID if available
    local org_id=$(echo "$response" | jq -r '.organizations[0].id // empty' 2>/dev/null)
    if [ -n "$org_id" ] && [ "$org_id" != "null" ]; then
        export ORGANIZATION_ID="$org_id"
        print_info "Organization ID stored in ORGANIZATION_ID: $ORGANIZATION_ID"
    fi
}

# Generate IDP Token
# Requirements: EMAIL
generate_idp_token() {
    print_info "Generating IDP token..."
    
    prompt_if_missing EMAIL "Enter user email"
    
    print_info "Generating token for: $EMAIL"
    
    # Check if we're in cli-tools directory or can access ltw command
    if command -v ltw &> /dev/null; then
        local output=$(ltw gateway console app:generate-jwt --idp_email="$EMAIL" 2>/dev/null)
    elif [ -f "cli-tools/ltw" ]; then
        local output=$(cd cli-tools && ./ltw gateway console app:generate-jwt --idp_email="$EMAIL" 2>/dev/null)
    else
        print_error "Cannot find 'ltw' command. Please run this from the cli-tools directory or ensure ltw is in PATH"
        return 1
    fi
    
    # Extract the token (last line that looks like a JWT)
    local token=$(echo "$output" | grep -oE '^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$' | tail -1)
    
    if [ -n "$token" ]; then
        export IDP_TOKEN="$token"
        print_success "IDP token generated and stored in IDP_TOKEN"
        print_info "Token: ${token:0:50}..."
    else
        print_error "Failed to generate IDP token"
        print_warning "Full output:"
        echo "$output"
        return 1
    fi
}

# Create Context Token
# Requirements: IDP_TOKEN, ORGANIZATION_ID
create_context_token() {
    print_info "Creating context token..."
    
    prompt_if_missing IDP_TOKEN "Enter IDP token"
    prompt_if_missing ORGANIZATION_ID "Enter Organization ID"
    
    print_info "Creating context token for org: $ORGANIZATION_ID"
    
    local http_code
    local response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/v1/contexts" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $IDP_TOKEN" \
        -d "{
            \"org_id\": \"$ORGANIZATION_ID\",
            \"accept_terms_and_conditions\": true,
            \"accept_privacy_policy\": true
        }")
    
    # Extract HTTP code (last line) and response body (everything else)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check for errors
    if ! check_api_error "$response" "$http_code"; then
        print_error "Failed to create context token"
        show_error_details "$response" "$http_code"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
    
    print_success "Context token created successfully"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    
    # Extract context token
    local context_token=$(echo "$response" | jq -r '.token // empty' 2>/dev/null)
    if [ -n "$context_token" ] && [ "$context_token" != "null" ]; then
        export CONTEXT_TOKEN="$context_token"
        print_success "Context token stored in CONTEXT_TOKEN"
        print_info "Token: ${context_token:0:50}..."
    fi
    
    # Extract user ID and org ID from claims
    local user_id=$(echo "$response" | jq -r '.claims.userId // empty' 2>/dev/null)
    local org_id=$(echo "$response" | jq -r '.claims.orgId // empty' 2>/dev/null)
    
    if [ -n "$user_id" ] && [ "$user_id" != "null" ]; then
        export USER_ID="$user_id"
        print_info "User ID stored in USER_ID: $USER_ID"
    fi
    if [ -n "$org_id" ] && [ "$org_id" != "null" ]; then
        export ORGANIZATION_ID="$org_id"
        print_info "Organization ID stored in ORGANIZATION_ID: $org_id"
    fi
}

# Verify Token Access
# Requirements: CONTEXT_TOKEN, IDP_TOKEN, ORGANIZATION_ID
verify_token_access() {
    print_info "Verifying token access..."
    
    prompt_if_missing CONTEXT_TOKEN "Enter context token"
    prompt_if_missing IDP_TOKEN "Enter IDP token"
    prompt_if_missing ORGANIZATION_ID "Enter Organization ID"
    
    print_info "Verifying access for org: $ORGANIZATION_ID"
    
    local http_code
    local response=$(curl -s -w "\n%{http_code}" "http://localhost:8050/v1/organizations/$ORGANIZATION_ID" \
        --header "x-context-token: $CONTEXT_TOKEN" \
        --header "Authorization: Bearer $IDP_TOKEN")
    
    # Extract HTTP code (last line) and response body (everything else)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check for errors
    if ! check_api_error "$response" "$http_code"; then
        print_error "Token verification failed"
        show_error_details "$response" "$http_code"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
    
    print_success "Token access verified successfully"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
}

# Get Task Lists
# Requirements: CONTEXT_TOKEN, IDP_TOKEN
get_task_lists() {
    print_info "Getting task lists..."
    
    prompt_if_missing CONTEXT_TOKEN "Enter context token"
    prompt_if_missing IDP_TOKEN "Enter IDP token"
    
    print_info "Fetching task lists..."
    
    local http_code
    local response=$(curl -s -w "\n%{http_code}" "http://localhost:8050/v1/task_lists" \
        --header "x-context-token: $CONTEXT_TOKEN" \
        --header "Authorization: Bearer $IDP_TOKEN")
    
    # Extract HTTP code (last line) and response body (everything else)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check for errors
    if ! check_api_error "$response" "$http_code"; then
        print_error "Failed to get task lists"
        show_error_details "$response" "$http_code"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
    
    print_success "Task lists retrieved successfully"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
}

# Create Task List
# Requirements: CONTEXT_TOKEN, IDP_TOKEN
# Optional: TASK_LIST_TITLE, TASK_LIST_DESCRIPTION
create_task_list() {
    print_info "Creating task list..."
    
    prompt_if_missing CONTEXT_TOKEN "Enter context token"
    prompt_if_missing IDP_TOKEN "Enter IDP token"
    
    local title="${TASK_LIST_TITLE:-Sample Task List}"
    local description="${TASK_LIST_DESCRIPTION:-A comprehensive task list with multiple sections and tasks}"
    local is_ai_draft="${TASK_LIST_IS_AI_DRAFT:-false}"
    
    print_info "Creating task list: $title"
    
    # Generate simple IDs for sections and tasks
    local section1_id="section-1-$(date +%s)"
    local section2_id="section-2-$(date +%s)"
    local section3_id="section-3-$(date +%s)"
    
    local task1_id="task-1-$(date +%s)"
    local task2_id="task-2-$(date +%s)"
    local task3_id="task-3-$(date +%s)"
    local task4_id="task-4-$(date +%s)"
    local task5_id="task-5-$(date +%s)"
    
    local http_code
    local response=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8050/v1/task_lists" \
        --header "x-context-token: $CONTEXT_TOKEN" \
        --header "Authorization: Bearer $IDP_TOKEN" \
        --header "Content-Type: application/json" \
        -d "{
            \"title\": \"$title\",
            \"description\": \"$description\",
            \"is_ai_draft\": $is_ai_draft,
            \"sections\": [
                {
                    \"id\": \"$section1_id\",
                    \"title\": \"Getting Started\",
                    \"sequence_order\": 1,
                    \"tasks\": [
                        {
                            \"id\": \"$task1_id\",
                            \"name\": \"Complete onboarding\",
                            \"event\": \"onboarding_complete\",
                            \"sequence_order\": 1
                        },
                        {
                            \"id\": \"$task2_id\",
                            \"name\": \"Review company policies\",
                            \"event\": \"\",
                            \"sequence_order\": 2
                        }
                    ]
                },
                {
                    \"id\": \"$section2_id\",
                    \"title\": \"Training & Development\",
                    \"sequence_order\": 2,
                    \"tasks\": [
                        {
                            \"id\": \"$task3_id\",
                            \"name\": \"Complete required training modules\",
                            \"event\": \"training_complete\",
                            \"sequence_order\": 1
                        },
                        {
                            \"id\": \"$task4_id\",
                            \"name\": \"Attend team meeting\",
                            \"event\": \"\",
                            \"sequence_order\": 2
                        }
                    ]
                },
                {
                    \"id\": \"$section3_id\",
                    \"title\": \"Final Steps\",
                    \"sequence_order\": 3,
                    \"tasks\": [
                        {
                            \"id\": \"$task5_id\",
                            \"name\": \"Submit final documentation\",
                            \"event\": \"documentation_submitted\",
                            \"sequence_order\": 1
                        }
                    ]
                }
            ]
        }")
    
    # Extract HTTP code (last line) and response body (everything else)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check for errors
    if ! check_api_error "$response" "$http_code"; then
        print_error "Failed to create task list"
        show_error_details "$response" "$http_code"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
    
    print_success "Task list created successfully"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    
    # Extract task list ID if available
    local task_list_id=$(echo "$response" | jq -r '.taskList.id // empty' 2>/dev/null)
    if [ -z "$task_list_id" ] || [ "$task_list_id" = "null" ]; then
        task_list_id=$(echo "$response" | jq -r '.task_list.id // empty' 2>/dev/null)
    fi
    if [ -n "$task_list_id" ] && [ "$task_list_id" != "null" ]; then
        export TASK_LIST_ID="$task_list_id"
        print_info "Task list ID stored in TASK_LIST_ID: $TASK_LIST_ID"
    fi
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

# Create User and Login: Create User → Generate IDP Token → Create Context Token → Verify Token Access
create_user_and_login() {
    print_info "Starting workflow: Create User → Generate IDP Token → Create Context Token → Verify Token Access"
    echo ""
    
    # Step 1: Create User
    print_info "=== Step 1: Creating User ==="
    if ! create_user; then
        print_error "Workflow failed at: Create User"
        return 1
    fi
    echo ""
    
    # Step 2: Generate IDP Token
    print_info "=== Step 2: Generating IDP Token ==="
    if ! generate_idp_token; then
        print_error "Workflow failed at: Generate IDP Token"
        return 1
    fi
    echo ""
    
    # Step 3: Create Context Token
    print_info "=== Step 3: Creating Context Token ==="
    if ! create_context_token; then
        print_error "Workflow failed at: Create Context Token"
        return 1
    fi
    echo ""
    
    # Step 4: Verify Token Access
    print_info "=== Step 4: Verifying Token Access ==="
    if ! verify_token_access; then
        print_error "Workflow failed at: Verify Token Access"
        return 1
    fi
    echo ""
    
    print_success "Create user and login workflow completed successfully!"
    print_info "Environment variables set:"
    echo "  EMAIL=$EMAIL"
    echo "  ORGANIZATION_ID=$ORGANIZATION_ID"
    echo "  USER_ID=${USER_ID:-not set}"
    echo "  IDP_TOKEN=${IDP_TOKEN:0:50}..."
    echo "  CONTEXT_TOKEN=${CONTEXT_TOKEN:0:50}..."
}

# Login: Generate IDP Token → Create Context Token → Verify Token Access
login() {
    print_info "Starting login workflow: Generate IDP Token → Create Context Token → Verify Token Access"
    echo ""
    
    # Step 1: Generate IDP Token
    print_info "=== Step 1: Generating IDP Token ==="
    if ! generate_idp_token; then
        print_error "Workflow failed at: Generate IDP Token"
        return 1
    fi
    echo ""
    
    # Step 2: Create Context Token
    print_info "=== Step 2: Creating Context Token ==="
    if ! create_context_token; then
        print_error "Workflow failed at: Create Context Token"
        return 1
    fi
    echo ""
    
    # Step 3: Verify Token Access
    print_info "=== Step 3: Verifying Token Access ==="
    if ! verify_token_access; then
        print_error "Workflow failed at: Verify Token Access"
        return 1
    fi
    echo ""
    
    print_success "Login workflow completed successfully!"
    print_info "Environment variables set:"
    echo "  EMAIL=$EMAIL"
    echo "  ORGANIZATION_ID=$ORGANIZATION_ID"
    echo "  USER_ID=${USER_ID:-not set}"
    echo "  IDP_TOKEN=${IDP_TOKEN:0:50}..."
    echo "  CONTEXT_TOKEN=${CONTEXT_TOKEN:0:50}..."
}

# Main menu (only shown when script is executed directly)
show_menu() {
    echo ""
    echo "=========================================="
    echo "  Local Environment API Helper"
    echo "=========================================="
    echo ""
    echo "Available functions:"
    echo "  1) create_user              - Create a new user"
    echo "  2) get_organizations        - Get organizations for a user"
    echo "  3) generate_idp_token       - Generate IDP token"
    echo "  4) create_context_token     - Create context token"
    echo "  5) verify_token_access     - Verify token access"
    echo "  6) get_task_lists          - Get task lists"
    echo "  7) create_task_list        - Create a task list with default values"
    echo "  8) ltw_env_reset           - Reset all environment variables"
    echo ""
    echo "Workflows:"
    echo "  9) create_user_and_login   - Create User → Generate IDP Token → Create Context Token → Verify"
    echo " 10) login                   - Generate IDP Token → Create Context Token → Verify"
    echo ""
    echo "  0) Exit"
    echo ""
}

# Main execution (only runs when script is executed directly, not when sourced)
main() {
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select an option: " choice
            echo ""
            
            case $choice in
                1) create_user ;;
                2) get_organizations ;;
                3) generate_idp_token ;;
                4) create_context_token ;;
                5) verify_token_access ;;
                6) get_task_lists ;;
                7) create_task_list ;;
                8) ltw_env_reset ;;
                9) create_user_and_login ;;
               10) login ;;
                0) print_info "Exiting..."; exit 0 ;;
                *) print_error "Invalid option. Please try again." ;;
            esac
            
            echo ""
            read -p "Press Enter to continue..."
        done
    else
        # Command-line mode - execute the function name passed as argument
        local function_name=$1
        if declare -f "$function_name" > /dev/null; then
            "$function_name"
        else
            print_error "Unknown function: $function_name"
            echo ""
            echo "Available functions:"
            declare -f | grep -E '^[a-zA-Z_][a-zA-Z0-9_]* \(\)' | sed 's/ ()//' | sort
            exit 1
        fi
    fi
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
