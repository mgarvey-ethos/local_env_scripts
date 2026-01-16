#!/bin/bash

# Organization Service Functions
# Functions for interacting with the organization service

# Create User
# Requirements: ORGANIZATION_ID, EMAIL, ROLE
# If SKIP_PROMPTS is set to "1", skips interactive prompts
create_user() {
    if [ "${SKIP_PROMPTS:-}" != "1" ]; then
        print_info "Creating user..."
        prompt_organization_id
        prompt_if_missing EMAIL "Enter user email"
        prompt_if_missing ROLE "Enter role (e.g., ROLE_ADMIN, ROLE_SUPER_ADMIN)"
    else
        # Still need to ensure ORGANIZATION_ID is set, but don't prompt
        if [ -z "${ORGANIZATION_ID:-}" ]; then
            print_error "ORGANIZATION_ID is required but not set"
            return 1
        fi
    fi
    
    local first_name="${FIRST_NAME:-feed}"
    local last_name="${LAST_NAME:-sensor}"
    
    if [ "${SKIP_PROMPTS:-}" != "1" ]; then
        print_info "Creating user: $EMAIL with role: $ROLE in org: $ORGANIZATION_ID"
    fi
    
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
        if [ "${SKIP_PROMPTS:-}" != "1" ]; then
            print_error "Failed to create user"
            show_error_details "$response" "$http_code"
            echo "$response" | jq '.' 2>/dev/null || echo "$response"
        fi
        return 1
    fi
    
    if [ "${SKIP_PROMPTS:-}" != "1" ]; then
        print_success "User created successfully"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        
        # Extract user ID if available
        local user_id=$(echo "$response" | jq -r '.id // empty' 2>/dev/null)
        if [ -n "$user_id" ] && [ "$user_id" != "null" ]; then
            export USER_ID="$user_id"
            print_info "User ID stored in USER_ID: $USER_ID"
        fi
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

# Create Organization
# Requirements: CONTEXT_TOKEN, IDP_TOKEN
# Optional: ORG_SLUG, ORG_NAME
create_organization() {
    print_info "Creating organization..."
    
    prompt_if_missing CONTEXT_TOKEN "Enter context token"
    prompt_if_missing IDP_TOKEN "Enter IDP token"
    
    local org_slug="${ORG_SLUG:-}"
    local org_name="${ORG_NAME:-}"
    
    if [ -z "$org_slug" ]; then
        prompt_if_missing ORG_SLUG "Enter organization slug"
        org_slug="$ORG_SLUG"
    fi
    
    if [ -z "$org_name" ]; then
        prompt_if_missing ORG_NAME "Enter organization name"
        org_name="$ORG_NAME"
    fi
    
    print_info "Creating organization: $org_name (slug: $org_slug)"
    
    local http_code
    local response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/v1/organizations" \
        --header "x-context-token: $CONTEXT_TOKEN" \
        --header "Authorization: Bearer $IDP_TOKEN" \
        --header "Content-Type: application/json" \
        -d "{
            \"slug\": \"$org_slug\",
            \"name\": \"$org_name\",
            \"status\": \"ACTIVE\"
        }")
    
    # Extract HTTP code (last line) and response body (everything else)
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')
    
    # Check for errors
    if ! check_api_error "$response" "$http_code"; then
        print_error "Failed to create organization"
        show_error_details "$response" "$http_code"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
    
    print_success "Organization created successfully"
    echo "$response" | jq '.' 2>/dev/null || echo "$response"
    
    # Extract organization ID if available
    local org_id=$(echo "$response" | jq -r '.organization.id // empty' 2>/dev/null)
    if [ -n "$org_id" ] && [ "$org_id" != "null" ]; then
        export ORGANIZATION_ID="$org_id"
        print_info "Organization ID stored in ORGANIZATION_ID: $ORGANIZATION_ID"
    fi
}

# Verify Token Access
# Requirements: CONTEXT_TOKEN, IDP_TOKEN, ORGANIZATION_ID
verify_token_access() {
    print_info "Verifying token access..."
    
    prompt_if_missing CONTEXT_TOKEN "Enter context token"
    prompt_if_missing IDP_TOKEN "Enter IDP token"
    prompt_organization_id
    
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
