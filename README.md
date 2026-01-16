# Local Environment Scripts

A collection of bash scripts that provide convenient helper functions for interacting with locally running services from `ltw/cli-tools`. These scripts automate common API interactions, handle authentication flows, and manage environment variables for local development workflows.

The main script (`local_env_curls.sh`) can be sourced into your shell session to add helper functions, or executed directly for an interactive menu-driven interface.

## Quick Start

```bash
# Source the script to add functions to your shell
source local_env_scripts/local_env_curls.sh

# Or run it directly for an interactive menu
./local_env_scripts/local_env_curls.sh
```

## Available Functions

### Core Functions

- **[`create_user`](#create_user)** - Create a new user in the organization service
- **[`get_organizations`](#get_organizations)** - Retrieve organizations for a user by email
- **[`generate_idp_token`](#generate_idp_token)** - Generate an Identity Provider (IDP) JWT token
- **[`create_context_token`](#create_context_token)** - Create a context token for authenticated API access
- **[`verify_token_access`](#verify_token_access)** - Verify that tokens provide proper access to an organization
- **[`get_task_lists`](#get_task_lists)** - Retrieve all task lists for the authenticated user
- **[`create_task_list`](#create_task_list)** - Create a new task list with default sample data

### Utility Functions

- **[`ltw_env_reset`](#ltw_env_reset)** - Clear all environment variables used by these scripts

### Workflow Functions

- **[`create_user_and_login`](#create_user_and_login)** - Complete workflow: Create user → Generate IDP token → Create context token → Verify access
- **[`login`](#login)** - Quick login workflow: Generate IDP token → Create context token → Verify access

---

## Detailed Function Documentation

### `create_user`

Creates a new user in the organization service. Requires an organization ID, email, and role. The function prompts for missing values and stores the created user ID in the `USER_ID` environment variable.

**Requirements:**
- `ORGANIZATION_ID` - UUID of the organization (prompted if missing)
- `EMAIL` - User email address (prompted if missing)
- `ROLE` - User role, e.g., `ROLE_ADMIN`, `ROLE_SUPER_ADMIN`, `ROLE_LEARNER` (prompted if missing)

**Optional Environment Variables:**
- `FIRST_NAME` - User's first name (defaults to "feed" if not set)
- `LAST_NAME` - User's last name (defaults to "sensor" if not set)

**Sets Environment Variables:**
- `USER_ID` - The UUID of the created user

**API Endpoint:**
- `POST $ORGANIZATION_SERVICE_URL/users`
- Uses `x-user-data` header with super admin role for authorization

---

### `get_organizations`

Retrieves a list of organizations associated with a user's email address. Automatically extracts and stores the first organization ID from the response.

**Requirements:**
- `EMAIL` - User email address (prompted if missing, URL-encoded automatically)

**Sets Environment Variables:**
- `ORGANIZATION_ID` - The ID of the first organization in the response

**API Endpoint:**
- `GET $GATEWAY_URL/v1/organizations?user_email={email}`

---

### `generate_idp_token`

Generates an Identity Provider (IDP) JWT token for local development. Uses the `ltw` command to execute the Symfony console command `app:generate-jwt` with the provided email.

**Requirements:**
- `EMAIL` - User email address (prompted if missing)

**Sets Environment Variables:**
- `IDP_TOKEN` - The generated JWT token

**Dependencies:**
- Requires `ltw` command to be available (either in PATH or in `cli-tools/ltw`)

**Note:** The token is valid for 24 hours and includes `sub`, `email`, and `jti` claims.

---

### `create_context_token`

Creates a context token that provides authenticated access to organization-specific resources. Requires both an IDP token and an organization ID. The context token includes user and organization claims.

**Requirements:**
- `IDP_TOKEN` - Identity Provider JWT token (prompted if missing)
- `ORGANIZATION_ID` - UUID of the organization (prompted if missing)

**Sets Environment Variables:**
- `CONTEXT_TOKEN` - The generated context token
- `USER_ID` - User ID extracted from token claims
- `ORGANIZATION_ID` - Organization ID extracted from token claims (may update existing value)

**API Endpoint:**
- `POST $GATEWAY_URL/v1/contexts`
- Requires `Authorization: Bearer $IDP_TOKEN` header

**Request Body:**
```json
{
  "org_id": "<organization_id>",
  "accept_terms_and_conditions": true,
  "accept_privacy_policy": true
}
```

---

### `verify_token_access`

Verifies that the provided IDP and context tokens grant proper access to an organization by making an authenticated request to fetch organization details.

**Requirements:**
- `CONTEXT_TOKEN` - Context token (prompted if missing)
- `IDP_TOKEN` - Identity Provider token (prompted if missing)
- `ORGANIZATION_ID` - UUID of the organization to verify access for (prompted if missing)

**API Endpoint:**
- `GET $GATEWAY_URL/v1/organizations/{organization_id}`
- Requires both `x-context-token` and `Authorization: Bearer` headers

---

### `get_task_lists`

Retrieves all task lists accessible to the authenticated user. Requires both IDP and context tokens.

**Requirements:**
- `CONTEXT_TOKEN` - Context token (prompted if missing)
- `IDP_TOKEN` - Identity Provider token (prompted if missing)

**API Endpoint:**
- `GET $GATEWAY_URL/v1/task_lists`
- Requires both `x-context-token` and `Authorization: Bearer` headers

---

### `create_task_list`

Creates a new task list with sample data including multiple sections and tasks. Useful for testing and development. All tasks include an `event` field (empty string if no event is specified) to avoid nil pointer issues.

**Requirements:**
- `CONTEXT_TOKEN` - Context token (prompted if missing)
- `IDP_TOKEN` - Identity Provider token (prompted if missing)

**Optional Environment Variables:**
- `TASK_LIST_TITLE` - Title for the task list (defaults to "Sample Task List")
- `TASK_LIST_DESCRIPTION` - Description for the task list (defaults to "A comprehensive task list with multiple sections and tasks")
- `TASK_LIST_IS_AI_DRAFT` - Whether the task list is an AI draft (defaults to `false`)

**Sets Environment Variables:**
- `TASK_LIST_ID` - The UUID of the created task list

**Default Task List Structure:**
- **Section 1: Getting Started** (2 tasks)
  - Complete onboarding (event: `onboarding_complete`)
  - Review company policies (event: empty)
- **Section 2: Training & Development** (2 tasks)
  - Complete required training modules (event: `training_complete`)
  - Attend team meeting (event: empty)
- **Section 3: Final Steps** (1 task)
  - Submit final documentation (event: `documentation_submitted`)

**API Endpoint:**
- `POST $GATEWAY_URL/v1/task_lists`
- Requires both `x-context-token` and `Authorization: Bearer` headers

---

### `ltw_env_reset`

Clears all environment variables used by the local environment scripts. Useful for starting fresh or cleaning up after testing.

**Unsets Environment Variables:**
- `EMAIL`
- `ORGANIZATION_ID`
- `USER_ID`
- `ROLE`
- `FIRST_NAME`
- `LAST_NAME`
- `IDP_TOKEN`
- `CONTEXT_TOKEN`
- `TASK_LIST_ID`
- `TASK_LIST_TITLE`
- `TASK_LIST_DESCRIPTION`
- `TASK_LIST_IS_AI_DRAFT`

**Note:** Configuration variables (`GATEWAY_URL`, `ORGANIZATION_SERVICE_URL`) are not unset by default to preserve custom configurations.

---

### `create_user_and_login`

Complete workflow function that orchestrates the full user creation and authentication flow:
1. Creates a new user
2. Generates an IDP token for that user
3. Creates a context token
4. Verifies token access

**Requirements:**
- `ORGANIZATION_ID` - Will be prompted during user creation
- `EMAIL` - Will be prompted during user creation
- `ROLE` - Will be prompted during user creation

**Sets Environment Variables:**
- All variables set by the individual functions in the workflow

**Error Handling:**
- Stops at the first failed step and reports which step failed

---

### `login`

Quick login workflow for existing users:
1. Generates an IDP token
2. Creates a context token
3. Verifies token access

**Requirements:**
- `EMAIL` - Will be prompted during IDP token generation
- `ORGANIZATION_ID` - Will be prompted during context token creation

**Sets Environment Variables:**
- All variables set by the individual functions in the workflow

**Error Handling:**
- Stops at the first failed step and reports which step failed

---

## Environment Variables Reference

### Configuration Variables

These variables control the base URLs for API endpoints:

- **`GATEWAY_URL`** (default: `http://localhost:8050`)
  - Base URL for the API Gateway
  - Used by: `get_organizations`, `create_context_token`, `verify_token_access`, `get_task_lists`, `create_task_list`

- **`ORGANIZATION_SERVICE_URL`** (default: `http://localhost:8002/organization/api`)
  - Base URL for the organization service (bypasses gateway)
  - Used by: `create_user`

### Authentication Variables

These variables store authentication tokens and user information:

- **`IDP_TOKEN`**
  - Identity Provider JWT token
  - Generated by: `generate_idp_token`
  - Used by: `create_context_token`, `verify_token_access`, `get_task_lists`, `create_task_list`

- **`CONTEXT_TOKEN`**
  - Context token for organization-specific access
  - Generated by: `create_context_token`
  - Used by: `verify_token_access`, `get_task_lists`, `create_task_list`

### User and Organization Variables

- **`EMAIL`**
  - User email address
  - Set by: User input (prompted)
  - Used by: `create_user`, `get_organizations`, `generate_idp_token`

- **`ORGANIZATION_ID`**
  - UUID of the organization
  - Set by: `get_organizations`, `create_context_token`, or user input
  - Used by: `create_user`, `create_context_token`, `verify_token_access`

- **`USER_ID`**
  - UUID of the user
  - Set by: `create_user`, `create_context_token`
  - Used by: None (informational)

- **`ROLE`**
  - User role (e.g., `ROLE_ADMIN`, `ROLE_SUPER_ADMIN`, `ROLE_LEARNER`)
  - Set by: User input (prompted)
  - Used by: `create_user`

- **`FIRST_NAME`** (optional, default: "feed")
  - User's first name
  - Used by: `create_user`

- **`LAST_NAME`** (optional, default: "sensor")
  - User's last name
  - Used by: `create_user`

### Task List Variables

- **`TASK_LIST_ID`**
  - UUID of a created task list
  - Set by: `create_task_list`
  - Used by: None (informational)

- **`TASK_LIST_TITLE`** (optional, default: "Sample Task List")
  - Title for task list creation
  - Used by: `create_task_list`

- **`TASK_LIST_DESCRIPTION`** (optional, default: "A comprehensive task list with multiple sections and tasks")
  - Description for task list creation
  - Used by: `create_task_list`

- **`TASK_LIST_IS_AI_DRAFT`** (optional, default: `false`)
  - Whether the task list is marked as an AI draft
  - Used by: `create_task_list`

---

## Usage Examples

### Example 1: Create a user and authenticate

```bash
source local_env_scripts/local_env_curls.sh

# Run the complete workflow
create_user_and_login

# Or step by step:
create_user
generate_idp_token
create_context_token
verify_token_access
```

### Example 2: Login with existing user

```bash
source local_env_scripts/local_env_curls.sh

# Quick login workflow
login
```

### Example 3: Create a custom task list

```bash
source local_env_scripts/local_env_curls.sh

# Set custom values
export TASK_LIST_TITLE="My Custom Task List"
export TASK_LIST_DESCRIPTION="Tasks for Q1 onboarding"

# Create the task list
create_task_list
```

### Example 4: Reset environment

```bash
source local_env_scripts/local_env_curls.sh

# Clear all variables
ltw_env_reset
```

---

## Error Handling

All functions include robust error handling that:
- Checks HTTP status codes (4xx/5xx indicate errors)
- Parses JSON error responses for API-specific error codes
- Displays clear error messages with details
- Returns non-zero exit codes on failure
- Workflow functions stop at the first error

Functions use `jq` for JSON parsing when available, falling back to plain text output if `jq` is not installed.

---

## Dependencies

- `bash` or `zsh` shell
- `curl` - For making HTTP requests
- `jq` (optional) - For pretty-printing JSON responses
- `ltw` command - For generating IDP tokens (must be in PATH or `cli-tools/ltw`)

---

## Notes

- All functions are designed to work with locally running services from `cli-tools/docker-compose.yml`
- Functions prompt for missing required variables interactively
- Environment variables persist across function calls in the same shell session
- The script can be sourced (to add functions to your shell) or executed directly (for interactive menu)
- Functions automatically URL-encode values where needed (e.g., email addresses in query parameters)
