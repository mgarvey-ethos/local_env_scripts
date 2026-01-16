#!/bin/bash

# Authentication Functions
# Functions for generating tokens and managing authentication

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
