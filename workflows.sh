#!/bin/bash

# Workflow Functions
# High-level workflow functions that combine multiple operations

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
