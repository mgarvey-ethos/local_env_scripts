#!/bin/bash

# Database Seeding Functions
# Functions for creating fixture data using the API functions

# Arrays of adjectives and names for random generation
ADJECTIVES=(
    "happy" "bright" "swift" "calm" "brave" "gentle" "clever" "witty" "bold" "kind"
    "wise" "quick" "sharp" "smooth" "solid" "fresh" "clear" "warm" "cool" "sweet"
    "quiet" "lively" "jolly" "merry" "cheerful" "peaceful" "serene" "tranquil" "calm" "steady"
    "strong" "mighty" "powerful" "robust" "sturdy" "firm" "stable" "secure" "safe" "sound"
    "bright" "shiny" "glossy" "polished" "sleek" "smooth" "silky" "velvet" "satin" "glossy"
    "vibrant" "colorful" "radiant" "brilliant" "dazzling" "sparkling" "gleaming" "glowing" "luminous" "radiant"
    "swift" "rapid" "fast" "quick" "speedy" "brisk" "nimble" "agile" "fleet" "hasty"
    "gentle" "tender" "soft" "mild" "smooth" "calm" "peaceful" "serene" "tranquil" "placid"
    "clever" "smart" "intelligent" "bright" "brilliant" "sharp" "keen" "astute" "shrewd" "witty"
    "bold" "brave" "courageous" "daring" "fearless" "valiant" "heroic" "gallant" "intrepid" "audacious"
)

FIRST_NAMES=(
    "James" "Mary" "John" "Patricia" "Robert" "Jennifer" "Michael" "Linda" "William" "Elizabeth"
    "David" "Barbara" "Richard" "Susan" "Joseph" "Jessica" "Thomas" "Sarah" "Charles" "Karen"
    "Christopher" "Nancy" "Daniel" "Lisa" "Matthew" "Betty" "Anthony" "Margaret" "Mark" "Sandra"
    "Donald" "Ashley" "Steven" "Kimberly" "Paul" "Emily" "Andrew" "Donna" "Joshua" "Michelle"
    "Kenneth" "Carol" "Kevin" "Amanda" "Brian" "Dorothy" "George" "Melissa" "Timothy" "Deborah"
    "Ronald" "Stephanie" "Edward" "Rebecca" "Jason" "Sharon" "Jeffrey" "Laura" "Ryan" "Cynthia"
    "Jacob" "Kathleen" "Gary" "Amy" "Nicholas" "Angela" "Eric" "Shirley" "Jonathan" "Anna"
    "Stephen" "Brenda" "Larry" "Pamela" "Justin" "Emma" "Scott" "Nicole" "Brandon" "Helen"
    "Benjamin" "Samantha" "Samuel" "Katherine" "Frank" "Christine" "Gregory" "Debra" "Raymond" "Rachel"
    "Alexander" "Carolyn" "Patrick" "Janet" "Jack" "Catherine" "Dennis" "Maria" "Jerry" "Heather"
    "Tyler" "Diane" "Aaron" "Julie" "Jose" "Joyce" "Adam" "Victoria" "Nathan" "Kelly"
    "Henry" "Christina" "Zachary" "Joan" "Douglas" "Evelyn" "Peter" "Judith" "Kyle" "Megan"
    "Noah" "Cheryl" "Ethan" "Andrea" "Jeremy" "Hannah" "Walter" "Jacqueline" "Christian" "Martha"
    "Keith" "Gloria" "Roger" "Teresa" "Terry" "Sara" "Gerald" "Janice" "Harold" "Marie"
    "Sean" "Julia" "Austin" "Grace" "Carl" "Judy" "Arthur" "Theresa" "Lawrence" "Madison"
    "Dylan" "Beverly" "Jesse" "Denise" "Jordan" "Marilyn" "Bryan" "Amber" "Billy" "Danielle"
    "Joe" "Brittany" "Bruce" "Diana" "Gabriel" "Abigail" "Logan" "Jane" "Alan" "Lori"
    "Juan" "Olivia" "Wayne" "Helen" "Roy" "Marie" "Ralph" "Janet" "Randy" "Catherine"
    "Eugene" "Frances" "Louis" "Ann" "Russell" "Kathryn" "Vincent" "Samantha" "Philip" "Debra"
    "Bobby" "Rachel" "Johnny" "Carolyn" "Willie" "Janet" "Randy" "Catherine" "Howard" "Maria"
)

LAST_NAMES=(
    "Smith" "Johnson" "Williams" "Brown" "Jones" "Garcia" "Miller" "Davis" "Rodriguez" "Martinez"
    "Hernandez" "Lopez" "Wilson" "Anderson" "Thomas" "Taylor" "Moore" "Jackson" "Martin" "Lee"
    "Thompson" "White" "Harris" "Sanchez" "Clark" "Ramirez" "Lewis" "Robinson" "Walker" "Young"
    "Allen" "King" "Wright" "Scott" "Torres" "Nguyen" "Hill" "Flores" "Green" "Adams"
    "Nelson" "Baker" "Hall" "Rivera" "Campbell" "Mitchell" "Carter" "Roberts" "Gomez" "Phillips"
    "Evans" "Turner" "Diaz" "Parker" "Cruz" "Edwards" "Collins" "Reyes" "Stewart" "Morris"
    "Morales" "Murphy" "Cook" "Rogers" "Gutierrez" "Ortiz" "Morgan" "Cooper" "Peterson" "Bailey"
    "Reed" "Kelly" "Howard" "Ramos" "Kim" "Cox" "Ward" "Richardson" "Watson" "Brooks"
    "Chavez" "Wood" "James" "Bennett" "Gray" "Mendoza" "Ruiz" "Hughes" "Price" "Alvarez"
    "Castillo" "Sanders" "Patel" "Myers" "Long" "Ross" "Foster" "Jimenez" "Powell" "Jenkins"
    "Perry" "Russell" "Sullivan" "Bell" "Coleman" "Butler" "Henderson" "Barnes" "Gonzales" "Fisher"
    "Vasquez" "Simmons" "Romero" "Jordan" "Patterson" "Alexander" "Hamilton" "Graham" "Reynolds" "Griffin"
    "Wallace" "Moreno" "West" "Cole" "Hayes" "Bryant" "Herrera" "Gibson" "Ellis" "Tran"
    "Medina" "Aguilar" "Stevens" "Murray" "Ford" "Castro" "Marshall" "Owens" "Harrison" "Fernandez"
    "Mcdonald" "Woods" "Washington" "Kennedy" "Wells" "Vargas" "Henry" "Chen" "Freeman" "Webb"
    "Tucker" "Guzman" "Burns" "Crawford" "Olson" "Simpson" "Porter" "Hunter" "Gordon" "Mendez"
    "Silva" "Shaw" "Snyder" "Mason" "Dixon" "Munoz" "Hunt" "Hicks" "Holmes" "Palmer"
    "Wagner" "Black" "Robertson" "Boyd" "Rose" "Stone" "Salazar" "Fox" "Warren" "Mills"
    "Meyer" "Rice" "Schmidt" "Garza" "Daniels" "Ferguson" "Nichols" "Stephens" "Soto" "Weaver"
    "Ryan" "Gardner" "Payne" "Grant" "Dunn" "Kelley" "Spencer" "Hawkins" "Arnold" "Pierce"
)

# Generate a random number between min and max (inclusive)
# Uses /dev/urandom for better randomness
random_number() {
    local min=$1
    local max=$2
    local range=$((max - min + 1))
    # Use /dev/urandom for better randomness, especially in scripts
    local rand_bytes=$(od -An -N4 -tu4 /dev/urandom 2>/dev/null | tr -d ' ')
    if [ -z "$rand_bytes" ] || [ "$rand_bytes" = "" ]; then
        # Fallback: combine RANDOM with process ID and timestamp
        rand_bytes=$((RANDOM + $$ + $(date +%s)))
    fi
    # Ensure positive number and get modulo
    rand_bytes=$((rand_bytes < 0 ? -rand_bytes : rand_bytes))
    echo $((rand_bytes % range + min))
}

# Get a random adjective
random_adjective() {
    local idx=$(random_number 0 $((${#ADJECTIVES[@]} - 1)))
    echo "${ADJECTIVES[$idx]}"
}

# Get a random first name
random_first_name() {
    local idx=$(random_number 0 $((${#FIRST_NAMES[@]} - 1)))
    echo "${FIRST_NAMES[$idx]}"
}

# Get a random last name
random_last_name() {
    local idx=$(random_number 0 $((${#LAST_NAMES[@]} - 1)))
    echo "${LAST_NAMES[$idx]}"
}

# Generate a random 4-digit number
# Uses timestamp + random + process ID to ensure uniqueness
random_4digit() {
    # Combine timestamp microseconds with random and process ID for uniqueness
    local timestamp_part=$(date +%s%N 2>/dev/null | cut -b14-17 || echo "0000")
    local random_part=$(random_number 0 9999)
    local pid_part=$(($$ % 1000))
    # Mix them for better distribution
    local combined=$((timestamp_part + random_part + pid_part))
    printf "%04d" $((combined % 10000))
}

# Generate organization slug (adjective + 4-digit number)
# Uses timestamp to ensure uniqueness
# If DETERMINISTIC_NAMING is set, uses sequential naming: org1, org2, etc.
generate_org_slug() {
    local org_num=${1:-}
    if [ "${DETERMINISTIC_NAMING:-}" = "1" ] && [ -n "$org_num" ]; then
        echo "org${org_num}"
    else
        local adj=$(random_adjective)
        # Use microseconds from timestamp + random for uniqueness
        local timestamp_part=$(date +%s%N 2>/dev/null | cut -b14-17 || echo "0000")
        local random_part=$(random_number 0 9999)
        local num=$((timestamp_part + random_part))
        num=$(printf "%04d" $((num % 10000)))
        echo "${adj}${num}"
    fi
}

# Generate organization name from slug (capitalized adjective + space + 4-digit number)
# Takes the slug and converts it to a name format
# If DETERMINISTIC_NAMING is set, uses: Organization 1, Organization 2, etc.
generate_org_name_from_slug() {
    local slug=$1
    if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
        # Extract number from org1, org2, etc.
        local org_num=$(echo "$slug" | sed 's/org//')
        echo "Organization ${org_num}"
    else
        # Extract adjective (everything before the 4-digit number at the end)
        local adj=$(echo "$slug" | sed 's/[0-9]\{4\}$//')
        # Extract 4-digit number (last 4 characters)
        local num=$(echo "$slug" | sed 's/.*\([0-9]\{4\}\)$/\1/')
        # Capitalize first letter of adjective
        adj=$(echo "${adj:0:1}" | tr '[:lower:]' '[:upper:]')${adj:1}
        echo "${adj} ${num}"
    fi
}

# Generate user email (FirstnameLastname@organization_slug.com)
# If DETERMINISTIC_NAMING is set, uses: org1_admin1@org1.com, org1_learner1@org1.com, etc.
generate_user_email() {
    local first_name=$1
    local last_name=$2
    local org_slug=$3
    local role=${4:-}
    local user_num=${5:-}
    
    if [ "${DETERMINISTIC_NAMING:-}" = "1" ] && [ -n "$role" ] && [ -n "$user_num" ]; then
        # Extract role type (ROLE_ADMIN -> admin, ROLE_LEARNER -> learner)
        local role_type=$(echo "$role" | tr '[:upper:]' '[:lower:]' | sed 's/role_//')
        echo "${org_slug}_${role_type}${user_num}@${org_slug}.com"
    else
        echo "${first_name}${last_name}@${org_slug}.com"
    fi
}

# Create an organization with users
# Parameters:
#   $1 - Number of admins (default: 5)
#   $2 - Number of learners (default: 200)
#   $3 - Organization number (for deterministic naming, optional)
create_organization_with_users() {
    local admin_count=${1:-5}
    local learner_count=${2:-200}
    local org_num=${3:-}
    
    print_info "Creating organization with ${admin_count} admin(s), and ${learner_count} learner(s)..."
    
    # Check for required tokens
    if [ -z "${CONTEXT_TOKEN:-}" ] || [ -z "${IDP_TOKEN:-}" ]; then
        print_error "CONTEXT_TOKEN and IDP_TOKEN are required. Please run 'login' first."
        return 1
    fi
    
    # Generate organization details
    local org_slug=$(generate_org_slug "$org_num")
    local org_name=$(generate_org_name_from_slug "$org_slug")
    
    print_info "Organization: ${org_name} (slug: ${org_slug})"
    
    # Store original ORGANIZATION_ID if set
    local original_org_id="${ORGANIZATION_ID:-}"
    
    # Create the organization first
    export ORG_SLUG="$org_slug"
    export ORG_NAME="$org_name"
    
    if ! create_organization; then
        print_error "Failed to create organization: ${org_name}"
        return 1
    fi
    
    local new_org_id="$ORGANIZATION_ID"
    print_success "Created organization: ${org_name} (ID: ${new_org_id})"
    
    # Create users in batches
    local user_count=$((admin_count + learner_count))
    print_info "Creating ${user_count} users..."
    
    # Create admin users
    print_info "Creating ${admin_count} admin(s)..."
    local admin_success=0
    local admin_failed=0
    for ((i=1; i<=admin_count; i++)); do
        if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
            # Deterministic naming: use org1_admin1, org1_admin2, etc.
            # Last name needs to be at least 2 characters for validation
            local first_name="Admin"
            local last_name=$(printf "%04d" "$i")  # Pad to 4 digits: 0001, 0002, etc.
            local email=$(generate_user_email "$first_name" "$last_name" "$org_slug" "ROLE_ADMIN" "$i")
        else
            local first_name=$(random_first_name)
            local last_name=$(random_last_name)
            local email=$(generate_user_email "$first_name" "$last_name" "$org_slug")
        fi
        
        export FIRST_NAME="$first_name"
        export LAST_NAME="$last_name"
        export EMAIL="$email"
        export ROLE="ROLE_ADMIN"
        export ORGANIZATION_ID="$new_org_id"
        export SKIP_PROMPTS="1"
        export NO_COLOR="1"
        
        # Suppress all output from create_user
        if create_user > /dev/null 2>&1; then
            ((admin_success++))
        else
            ((admin_failed++))
        fi
        unset SKIP_PROMPTS
        unset NO_COLOR
        
        # Update progress on same line (use \r to overwrite, no newline)
        printf "\r  Admins: %d/%d created" "$admin_success" "$admin_count" >&2
        
        sleep 0.05
    done
    # Print newline after progress and show summary
    echo ""
    if [ $admin_failed -eq 0 ]; then
        print_success "Created ${admin_success} admin(s)"
    else
        print_warning "Created ${admin_success} admin(s), ${admin_failed} failed"
    fi
    
    # Create learner users
    print_info "Creating ${learner_count} learner(s)..."
    local learner_success=0
    local learner_failed=0
    for ((i=1; i<=learner_count; i++)); do
        if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
            # Deterministic naming: use org1_learner1, org1_learner2, etc.
            # Last name needs to be at least 2 characters for validation
            local first_name="Learner"
            local last_name=$(printf "%04d" "$i")  # Pad to 4 digits: 0001, 0002, etc.
            local email=$(generate_user_email "$first_name" "$last_name" "$org_slug" "ROLE_LEARNER" "$i")
        else
            local first_name=$(random_first_name)
            local last_name=$(random_last_name)
            local email=$(generate_user_email "$first_name" "$last_name" "$org_slug")
        fi
        
        export FIRST_NAME="$first_name"
        export LAST_NAME="$last_name"
        export EMAIL="$email"
        export ROLE="ROLE_LEARNER"
        export ORGANIZATION_ID="$new_org_id"
        export SKIP_PROMPTS="1"
        export NO_COLOR="1"
        
        # Suppress all output from create_user
        if create_user > /dev/null 2>&1; then
            ((learner_success++))
        else
            ((learner_failed++))
        fi
        unset SKIP_PROMPTS
        unset NO_COLOR
        
        # Update progress on same line (use \r to overwrite, no newline)
        printf "\r  Learners: %d/%d created" "$learner_success" "$learner_count" >&2
        
        sleep 0.02
    done
    # Print newline after progress and show summary
    echo ""
    if [ $learner_failed -eq 0 ]; then
        print_success "Created ${learner_success} learner(s)"
    else
        print_warning "Created ${learner_success} learner(s), ${learner_failed} failed"
    fi
    
    # Restore original ORGANIZATION_ID if it was set
    if [ -n "$original_org_id" ]; then
        export ORGANIZATION_ID="$original_org_id"
    else
        unset ORGANIZATION_ID
    fi
    
    print_success "Completed creating organization: ${org_name} with ${user_count} users"
}

# Create organizations in batch (without users)
# Returns array of organization IDs via global variable ORG_IDS
create_organizations_batch() {
    local org_count=$1
    local admin_count=$2
    local learner_count=$3
    
    print_info "Creating ${org_count} organizations..."
    
    # Check for required tokens
    if [ -z "${CONTEXT_TOKEN:-}" ] || [ -z "${IDP_TOKEN:-}" ]; then
        print_error "CONTEXT_TOKEN and IDP_TOKEN are required. Please run 'login' first."
        return 1
    fi
    
    # Store original ORGANIZATION_ID if set
    local original_org_id="${ORGANIZATION_ID:-}"
    
    # Array to store organization IDs
    ORG_IDS=()
    ORG_SLUGS=()
    local org_success=0
    local org_failed=0
    
    for ((org=1; org<=org_count; org++)); do
        local org_slug=$(generate_org_slug "$org")
        local org_name=$(generate_org_name_from_slug "$org_slug")
        
        export ORG_SLUG="$org_slug"
        export ORG_NAME="$org_name"
        export SKIP_PROMPTS="1"
        export NO_COLOR="1"
        
        if create_organization > /dev/null 2>&1; then
            ORG_IDS+=("$ORGANIZATION_ID")
            ORG_SLUGS+=("$org_slug")
            ((org_success++))
        else
            ((org_failed++))
        fi
        unset SKIP_PROMPTS
        unset NO_COLOR
        
        printf "\r  Organizations Created: %d/%d" "$org_success" "$org_count" >&2
        sleep 0.01
    done
    echo "" >&2
    
    if [ $org_failed -eq 0 ]; then
        print_success "Created ${org_success} organization(s)"
    else
        print_warning "Created ${org_success} organization(s), ${org_failed} failed"
    fi
    
    # Restore original ORGANIZATION_ID if it was set
    if [ -n "$original_org_id" ]; then
        export ORGANIZATION_ID="$original_org_id"
    else
        unset ORGANIZATION_ID
    fi
}

# Create admins across all organizations
create_admins_batch() {
    local admin_count_per_org=$1
    local total_orgs=${#ORG_IDS[@]}
    local total_admins=$((total_orgs * admin_count_per_org))
    
    print_info "Creating ${total_admins} admin(s) across ${total_orgs} organization(s)..."
    
    local admin_success=0
    local admin_failed=0
    local current_admin=0
    
    for org_idx in "${!ORG_IDS[@]}"; do
        local org_id="${ORG_IDS[$org_idx]}"
        local org_slug="${ORG_SLUGS[$org_idx]}"
        
        for ((i=1; i<=admin_count_per_org; i++)); do
            ((current_admin++))
            
            if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
                local first_name="Admin"
                local last_name=$(printf "%04d" "$i")
                local email=$(generate_user_email "$first_name" "$last_name" "$org_slug" "ROLE_ADMIN" "$i")
            else
                local first_name=$(random_first_name)
                local last_name=$(random_last_name)
                local email=$(generate_user_email "$first_name" "$last_name" "$org_slug")
            fi
            
            export FIRST_NAME="$first_name"
            export LAST_NAME="$last_name"
            export EMAIL="$email"
            export ROLE="ROLE_ADMIN"
            export ORGANIZATION_ID="$org_id"
            export SKIP_PROMPTS="1"
            export NO_COLOR="1"
            
            if create_user > /dev/null 2>&1; then
                ((admin_success++))
            else
                ((admin_failed++))
            fi
            unset SKIP_PROMPTS
            unset NO_COLOR
            
            printf "\r  Admins Created: %d/%d" "$admin_success" "$total_admins" >&2
            sleep 0.02
        done
    done
    echo "" >&2
    
    if [ $admin_failed -eq 0 ]; then
        print_success "Created ${admin_success} admin(s)"
    else
        print_warning "Created ${admin_success} admin(s), ${admin_failed} failed"
    fi
}

# Create learners across all organizations
create_learners_batch() {
    local learner_count_per_org=$1
    local total_orgs=${#ORG_IDS[@]}
    local total_learners=$((total_orgs * learner_count_per_org))
    
    print_info "Creating ${total_learners} learner(s) across ${total_orgs} organization(s)..."
    
    local learner_success=0
    local learner_failed=0
    local current_learner=0
    
    for org_idx in "${!ORG_IDS[@]}"; do
        local org_id="${ORG_IDS[$org_idx]}"
        local org_slug="${ORG_SLUGS[$org_idx]}"
        
        for ((i=1; i<=learner_count_per_org; i++)); do
            ((current_learner++))
            
            if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
                local first_name="Learner"
                local last_name=$(printf "%04d" "$i")
                local email=$(generate_user_email "$first_name" "$last_name" "$org_slug" "ROLE_LEARNER" "$i")
            else
                local first_name=$(random_first_name)
                local last_name=$(random_last_name)
                local email=$(generate_user_email "$first_name" "$last_name" "$org_slug")
            fi
            
            export FIRST_NAME="$first_name"
            export LAST_NAME="$last_name"
            export EMAIL="$email"
            export ROLE="ROLE_LEARNER"
            export ORGANIZATION_ID="$org_id"
            export SKIP_PROMPTS="1"
            export NO_COLOR="1"
            
            if create_user > /dev/null 2>&1; then
                ((learner_success++))
            else
                ((learner_failed++))
            fi
            unset SKIP_PROMPTS
            unset NO_COLOR
            
            printf "\r  Learners Created: %d/%d" "$learner_success" "$total_learners" >&2
            sleep 0.01
        done
    done
    echo "" >&2
    
    if [ $learner_failed -eq 0 ]; then
        print_success "Created ${learner_success} learner(s)"
    else
        print_warning "Created ${learner_success} learner(s), ${learner_failed} failed"
    fi
}

# Scenario 1: 10 organizations, each with 5 admins, and 200 learners
seed_scenario_1() {
    print_info "=== Scenario 1: 10 organizations ==="
    print_info "Each org: 5 admins, 200 learners"
    if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
        print_info "Using deterministic naming"
    fi
    
    # Create all organizations first
    create_organizations_batch 10 5 200
    
    # Then create all admins
    create_admins_batch 5
    
    # Then create all learners
    create_learners_batch 200
    
    print_success "Scenario 1 complete!"
}

# Scenario 2: 100 organizations, each with 10 admins, and 400 learners
seed_scenario_2() {
    print_info "=== Scenario 2: 100 organizations ==="
    print_info "Each org: 10 admins, 400 learners"
    if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
        print_info "Using deterministic naming"
    fi
    
    # Create all organizations first
    create_organizations_batch 100 10 400
    
    # Then create all admins
    create_admins_batch 10
    
    # Then create all learners
    create_learners_batch 400
    
    print_success "Scenario 2 complete!"
}

# Scenario 3: 1000 organizations, each with 20 admins, and 1000 learners
seed_scenario_3() {
    print_info "=== Scenario 3: 1000 organizations ==="
    print_info "Each org: 20 admins, 1000 learners"
    if [ "${DETERMINISTIC_NAMING:-}" = "1" ]; then
        print_info "Using deterministic naming"
    fi
    print_warning "This will create 1,020,000 users total. This may take a very long time!"
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_info "Cancelled."
        return 1
    fi
    
    # Create all organizations first
    create_organizations_batch 1000 20 1000
    
    # Then create all admins
    create_admins_batch 20
    
    # Then create all learners
    create_learners_batch 1000
    
    print_success "Scenario 3 complete!"
}
