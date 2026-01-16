#!/bin/bash

# Local Environment cURL Helper Script
# Source this file to add functions to your shell session:
#   source local_env_curls.sh
# Or: . local_env_curls.sh

# Get the directory where this script is located
# This works whether the script is sourced or executed directly, and handles both relative and absolute paths
# ${BASH_SOURCE[0]} gives us the path to the script file, even when sourced
# We resolve it to an absolute path to ensure it works from any directory
if [ -n "${BASH_SOURCE[0]}" ]; then
    # Resolve the script path to an absolute path
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback if BASH_SOURCE is not available (shouldn't happen in bash/zsh)
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Verify SCRIPT_DIR was resolved correctly
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Could not determine script directory" >&2
    return 1 2>/dev/null || exit 1
fi

# Source utility functions first (they're needed by all other modules)
if [ ! -f "$SCRIPT_DIR/utils.sh" ]; then
    echo "Error: Could not find utils.sh in $SCRIPT_DIR" >&2
    return 1 2>/dev/null || exit 1
fi
source "$SCRIPT_DIR/utils.sh"

# Source service-specific modules
for module in organization.sh auth.sh tasklist.sh workflows.sh; do
    if [ ! -f "$SCRIPT_DIR/$module" ]; then
        echo "Error: Could not find $module in $SCRIPT_DIR" >&2
        return 1 2>/dev/null || exit 1
    fi
    source "$SCRIPT_DIR/$module"
done

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
