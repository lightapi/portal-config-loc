#!/bin/bash

shopt -s extglob

# Base directory
BASE_DIR=~/lightapi
cd "$BASE_DIR" || { echo "Error: Cannot cd to $BASE_DIR"; exit 1; }

echo "Checking repository statuses with mgitstatus..."
REPO_CHANGES_RAW=$(mgitstatus)

# Extract projects with changes into arrays
CHANGED_PROJECTS=()
while IFS= read -r line; do
    if [[ "$line" =~ \./ ]]; then
        repo=$(echo "$line" | sed 's/^\.\///; s/:.*//')
        status=$(echo "$line" | sed 's/.*: //')
        
        # Check if this repo has changes
        if [[ "$status" == *"Uncommitted changes"* ]] || \
           [[ "$status" == *"Untracked files"* ]] || \
           [[ "$status" == *"Needs upstream"* ]]; then
            CHANGED_PROJECTS+=("$repo")
            echo "  ✓ $repo has changes"
        fi
    fi
done <<< "$REPO_CHANGES_RAW"

# Convert array to associative array for faster lookup
declare -A CHANGED_PROJECTS_MAP
for project in "${CHANGED_PROJECTS[@]}"; do
    CHANGED_PROJECTS_MAP["$project"]=1
done

# Function to check if project has changes
project_has_changes() {
    local project_name="$1"
    [[ -n "${CHANGED_PROJECTS_MAP[$project_name]}" ]]
}

# Function to build project
build_project() {
    local project_dir="$1"
    local project_name="$2"
    
    if project_has_changes "$project_name"; then
        echo "Building $project_name..."
        cd "$BASE_DIR/$project_dir" && mvn clean install
        if [ $? -ne 0 ]; then
            echo "Error: Maven build failed in $project_dir"
            exit 1
        fi
        cd "$BASE_DIR"
        return 0
    fi
}

# Function to docker project
docker_project() {
    local project_dir="$1"
    local project_name="$2"
    
    if project_has_changes "light-portal"; then
        echo "Dockerizing $project_name..."
        cd "$BASE_DIR/$project_dir" && ./build.sh 2.2.1 -l
        if [ $? -ne 0 ]; then
            echo "Error: Docker build failed in $project_dir"
            exit 1
        fi
        cd "$BASE_DIR"
        return 0
    fi
}

# Arrays to track what was built
BUILT_PROJECTS=()
QUERY_PROJECTS_BUILT=()
COMMAND_PROJECTS_BUILT=()

# Build light-portal (always check)
if build_project "light-portal" "light-portal"; then
    BUILT_PROJECTS+=("light-portal")
fi

# Define all projects we care about (only -query and -command)
projects=(
    "user" "oauth" "rule" "role" "group" "position" 
    "attribute" "client" "service" "host" "product" 
    "deployment" "instance" "config" "category" 
    "schema" "tag" "schedule" "ref"
)

# Also include other projects mentioned in mgitstatus output
other_projects=(
    "template" "page" "blog" "error" "hybrid" "form"
    "news" "document" "maproot"
)

# Combine all projects
all_projects=("${projects[@]}" "${other_projects[@]}")

# Build query and command projects
for project in "${all_projects[@]}"; do
    query_project="${project}-query"
    command_project="${project}-command"
    
    # Query project
    if build_project "$query_project" "$query_project"; then
        BUILT_PROJECTS+=("$query_project")
        QUERY_PROJECTS_BUILT+=("$project")
    fi
    
    # Command project
    if build_project "$command_project" "$command_project"; then
        BUILT_PROJECTS+=("$command_project")
        COMMAND_PROJECTS_BUILT+=("$project")
    fi
done

# Build hybrid-query and hybrid-command projects

if docker_project "hybrid-command" "hybrid-command"; then
    BUILT_PROJECTS+=("hybrid-command")
fi

if docker_project "hybrid-query" "hybrid-query"; then
    BUILT_PROJECTS+=("hybrid-query")
fi

echo "========================================="
echo "Build summary:"
echo "Total projects checked: $(mgitstatus | wc -l)"
echo "Projects built: ${#BUILT_PROJECTS[@]}"
if [ ${#BUILT_PROJECTS[@]} -eq 0 ]; then
    echo "No projects needed building - everything is up to date!"
    
    # Check if we should still clean and copy (maybe JARs were deleted)
    read -p "Clean and copy anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo "Projects built:"
    for project in "${BUILT_PROJECTS[@]}"; do
        echo "  - $project"
    done
fi
echo "========================================="

# Clean destination directories (only if we have projects to copy or user chose to)
if [ ${#QUERY_PROJECTS_BUILT[@]} -gt 0 ] || [ ${#COMMAND_PROJECTS_BUILT[@]} -gt 0 ]; then
    echo "Cleaning destination directories..."
    find portal-config-loc/all-in-one/hybrid-query/service -maxdepth 1 -type f ! -name '.gitkeep' -delete 2>/dev/null
    find portal-config-loc/all-in-one/hybrid-command/service -maxdepth 1 -type f ! -name '.gitkeep' -delete 2>/dev/null

    find portal-config-loc/all-in-pg/hybrid-query/service -maxdepth 1 -type f ! -name '.gitkeep' -delete 2>/dev/null
    find portal-config-loc/all-in-pg/hybrid-command/service -maxdepth 1 -type f ! -name '.gitkeep' -delete 2>/dev/null

    find portal-config-loc/all-in-light/hybrid-query/service -maxdepth 1 -type f ! -name '.gitkeep' -delete 2>/dev/null
    find portal-config-loc/all-in-light/hybrid-command/service -maxdepth 1 -type f ! -name '.gitkeep' -delete 2>/dev/null
fi

# Copy JAR files for projects that were built
echo "Copying JAR files..."

# Function to copy JAR file
copy_jar() {
    local project="$1"
    local project_type="$2"  # "query" or "command"
    local dest_dir="$3"
    
    local jar_pattern="${project}-${project_type}-*.jar"
    local jar_file=$(find "$BASE_DIR/${project}-${project_type}/target" \
        -name "$jar_pattern" \
        ! -name "*-javadoc.jar" \
        ! -name "*-sources.jar" \
        2>/dev/null | head -1)
    
    if [ -f "$jar_file" ]; then
        echo "  Copying ${project}-${project_type} to $dest_dir..."
        cp "$jar_file" "$dest_dir/"
    else
        echo "  Warning: JAR not found for ${project}-${project_type}"
    fi
}

# Copy query projects
for project in "${QUERY_PROJECTS_BUILT[@]}"; do
    copy_jar "$project" "query" "portal-config-loc/all-in-one/hybrid-query/service"
    copy_jar "$project" "query" "portal-config-loc/all-in-pg/hybrid-query/service"
    copy_jar "$project" "query" "portal-config-loc/all-in-light/hybrid-query/service"
done

# Copy command projects
for project in "${COMMAND_PROJECTS_BUILT[@]}"; do
    copy_jar "$project" "command" "portal-config-loc/all-in-one/hybrid-command/service"
    copy_jar "$project" "command" "portal-config-loc/all-in-pg/hybrid-command/service"
    copy_jar "$project" "command" "portal-config-loc/all-in-light/hybrid-command/service"
done


echo "========================================="
echo "Build and copy completed successfully!"
echo "Query projects built: ${#QUERY_PROJECTS_BUILT[@]}"
echo "Command projects built: ${#COMMAND_PROJECTS_BUILT[@]}"
echo "========================================="

