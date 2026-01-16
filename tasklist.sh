#!/bin/bash

# Tasklist Service Functions
# Functions for interacting with the tasklist service

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
