#!/bin/bash
# deploy.sh - Full deployment script with Docker Compose management

set -e  # Exit on error

# Configuration
BASE_DIR=~/lightapi
DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-one"
SERVICE_ASSET_REPO="$BASE_DIR/service-asset"
DOCKER_COMPOSE_FILES=()
DOCKER_COMPOSE_CMD=(docker compose)
CONTROLLER_TYPE=""

# Check for config argument
if [[ "$1" == "kafka" ]]; then
    DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-one"
    shift
elif [[ "$1" == "pg" ]]; then
    DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-pg"
    shift
elif [[ "$1" == "lt" ]]; then
    DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-lt"
    shift
fi

DOCKER_COMPOSE_FILES=(-f "$DOCKER_COMPOSE_DIR/docker-compose.yml")

if [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-pg" ]] || [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]]; then
    CONTROLLER_TYPE="${1:-java}"

    case "$CONTROLLER_TYPE" in
        java)
            DOCKER_COMPOSE_FILES+=(-f "$DOCKER_COMPOSE_DIR/docker-compose-java.yml")
            shift
            ;;
        rust)
            DOCKER_COMPOSE_FILES+=(-f "$DOCKER_COMPOSE_DIR/docker-compose-rust.yml")
            shift
            ;;
        *)
            if [[ -n "$CONTROLLER_TYPE" ]] && [[ ! "$CONTROLLER_TYPE" =~ ^(stop|start|restart|status|logs|help|-h|--help)$ ]]; then
                echo "Invalid controller type: $CONTROLLER_TYPE"
                echo "Usage: $0 [kafka|pg|lt] [java|rust] [command]"
                exit 1
            fi

            CONTROLLER_TYPE="java"
            DOCKER_COMPOSE_FILES+=(-f "$DOCKER_COMPOSE_DIR/docker-compose-java.yml")
            ;;
    esac
fi

LOG_FILE="/tmp/deploy_$(date +%Y%m%d_%H%M%S).log"
BUILD_SCRIPT="$BASE_DIR/copy-service-local.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

copy_missing_dir_contents() {
    local target_dir="$1"
    local repo_dir="$2"
    local asset_name="$3"
    local file_pattern="${4:-*}"
    local recursive_copy="${5:-false}"

    mkdir -p "$target_dir"

    if [[ "$recursive_copy" == "true" ]]; then
        if find "$target_dir" -mindepth 1 | grep -q .; then
            log_info "$asset_name already present in $target_dir"
            return 0
        fi
    elif find "$target_dir" -maxdepth 1 -type f -name "$file_pattern" | grep -q .; then
        log_info "$asset_name already present in $target_dir"
        return 0
    fi

    if [ ! -d "$SERVICE_ASSET_REPO" ]; then
        log_error "$asset_name missing in $target_dir and service-asset repo not found at $SERVICE_ASSET_REPO"
        return 1
    fi

    if [ ! -d "$repo_dir" ]; then
        log_error "$asset_name missing in $target_dir and source folder not found: $repo_dir"
        return 1
    fi

    if [[ "$recursive_copy" == "true" ]]; then
        if ! find "$repo_dir" -mindepth 1 | grep -q .; then
            log_error "No asset files found in $repo_dir for $asset_name"
            return 1
        fi

        log_info "Copying $asset_name from $repo_dir to $target_dir"
        cp -R "$repo_dir"/. "$target_dir"/
    else
        if ! find "$repo_dir" -maxdepth 1 -type f -name "$file_pattern" | grep -q .; then
            log_error "No matching files found in $repo_dir for $asset_name"
            return 1
        fi

        log_info "Copying $asset_name from $repo_dir to $target_dir"
        cp "$repo_dir"/$file_pattern "$target_dir"/
    fi
}

ensure_service_assets() {
    local query_target="$DOCKER_COMPOSE_DIR/hybrid-query/service"
    local command_target="$DOCKER_COMPOSE_DIR/hybrid-command/service"
    local lightapi_target="$DOCKER_COMPOSE_DIR/light-gateway/lightapi/dist"
    local signin_target="$DOCKER_COMPOSE_DIR/light-gateway/signin/dist"

    copy_missing_dir_contents "$query_target" "$SERVICE_ASSET_REPO/hybrid-query" "hybrid-query jars" "*.jar" || exit 1
    copy_missing_dir_contents "$command_target" "$SERVICE_ASSET_REPO/hybrid-command" "hybrid-command jars" "*.jar" || exit 1
    copy_missing_dir_contents "$lightapi_target" "$SERVICE_ASSET_REPO/lightapi/dist" "lightapi UI assets" "*" "true" || exit 1
    copy_missing_dir_contents "$signin_target" "$SERVICE_ASSET_REPO/signin/dist" "signin UI assets" "*" "true" || exit 1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if docker compose exists
    if ! docker compose version &> /dev/null; then
        log_error "docker compose not found. Please install Docker with Compose plugin support."
        exit 1
    fi

    # Check if docker-compose.yml exists
    if [ ! -f "$DOCKER_COMPOSE_DIR/docker-compose.yml" ]; then
        log_error "docker-compose.yml not found at $DOCKER_COMPOSE_DIR"
        exit 1
    fi

    if [ "${#DOCKER_COMPOSE_FILES[@]}" -gt 3 ]; then
        local override_file="${DOCKER_COMPOSE_FILES[3]}"
        if [ ! -f "$override_file" ]; then
            log_error "docker-compose override file not found at $override_file"
            exit 1
        fi
    fi

    ensure_service_assets

    log_success "All prerequisites met"
}

# Stop Docker Compose
stop_docker_compose() {
    log_info "Stopping Docker Compose services..."

    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }

    # Check if any containers are running
    if "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps --services --filter "status=running" 2>/dev/null | grep -q .; then
        log_info "Stopping running containers..."
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" down --timeout 30

        # Wait for containers to stop
        local max_wait=60
        local wait_time=0

        while "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps --services --filter "status=running" 2>/dev/null | grep -q .; do
            if [ $wait_time -ge $max_wait ]; then
                log_warning "Some containers are still running after $max_wait seconds"
                log_info "Force stopping containers..."
                "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" down --timeout 10
                break
            fi
            sleep 5
            wait_time=$((wait_time + 5))
        done

        log_success "Docker Compose services stopped"
    else
        log_info "No running Docker Compose services found"
    fi
}

# Start Docker Compose
start_docker_compose() {
    log_info "Starting Docker Compose services..."

    ensure_service_assets || exit 1

    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }

    # Start services in detached mode
    log_info "Starting services..."
    if "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" up -d --build; then
        log_success "Docker Compose services started"

        # Show status
        log_info "Current service status:"
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps

        # Tail logs for a few seconds to show startup
        log_info "Showing startup logs (tail for 10 seconds)..."
        timeout 10 "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" logs -f --tail=10 2>/dev/null || true
    else
        log_error "Failed to start Docker Compose services"
        return 1
    fi
}

# Verify services are healthy
verify_services() {
    log_info "Verifying services are healthy..."

    cd "$DOCKER_COMPOSE_DIR" || return 1

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        log_info "Health check attempt $attempt of $max_attempts..."

        # Count total services and healthy services
        local total_services=$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps --services | wc -l)
        local healthy_services=$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps --services | while read service; do
            if "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps --filter "status=running" "$service" | grep -q "Up"; then
                echo "1"
            fi
        done | wc -l)

        if [ "$healthy_services" -eq "$total_services" ] && [ "$total_services" -gt 0 ]; then
            log_success "All $total_services services are running"
            return 0
        fi

        log_info "$healthy_services of $total_services services running..."
        sleep 10
        attempt=$((attempt + 1))
    done

    log_warning "Some services may not be fully healthy after $max_attempts attempts"
    log_info "Current service status:"
    "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps
    return 1
}

# Show deployment summary
show_summary() {
    log_info "=== Deployment Summary ==="
    log_info "Log file: $LOG_FILE"
    log_info "Docker Compose directory: $DOCKER_COMPOSE_DIR"
    if [ -n "$CONTROLLER_TYPE" ]; then
        log_info "Controller type: $CONTROLLER_TYPE"
    fi

    cd "$DOCKER_COMPOSE_DIR" && {
        log_info "Running containers:"
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps --services | while read service; do
            status=$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps "$service" | tail -1 | awk '{print $3}')
            log_info "  - $service: $status"
        done

        log_info "Service URLs (if applicable):"
        # Add any specific service URL checks here
        # Example:
        # log_info "  - API Gateway: http://localhost:8080"
    }
}

# Main deployment process
main() {
    log_info "Starting full deployment process"
    log_info "Logging to: $LOG_FILE"
    if [ -n "$CONTROLLER_TYPE" ]; then
        log_info "Selected pg service type: $CONTROLLER_TYPE"
    fi

    # Step 1: Check prerequisites
    check_prerequisites

    # Step 2: Stop Docker Compose
    stop_docker_compose

    # Step 3: Start Docker Compose
    if ! start_docker_compose; then
        log_error "Failed to start Docker Compose"
        exit 1
    fi

    # Step 4: Verify services
    verify_services

    # Step 5: Show summary
    show_summary

    log_success "Deployment completed successfully!"
    log_info "To view logs: docker compose ${DOCKER_COMPOSE_FILES[*]} logs -f"
}

# Handle script arguments
case "${1:-}" in
    "stop")
        stop_docker_compose
        ;;
    "start")
        start_docker_compose
        ;;
    "restart")
        stop_docker_compose
        sleep 2
        start_docker_compose
        ;;
    "status")
        cd "$DOCKER_COMPOSE_DIR" && "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps
        ;;
    "logs")
        cd "$DOCKER_COMPOSE_DIR" && "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" logs -f --tail=100
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [config] [controller] [command]"
        echo ""
        echo "Config (optional):"
        echo "  kafka           Use Kafka configuration (default)"
        echo "  pg              Use Postgres configuration"
        echo "  lt              Use Light Postgres configuration (one hybrid-query)"
        echo ""
        echo "Service type (optional, pg only):"
        echo "  java            Use Java controller and OAuth services (default for pg)"
        echo "  rust            Use Rust controller and OAuth services"
        echo ""
        echo "Commands:"
        echo "  (no command)    Full deployment (stop, build, start)"
        echo "  stop            Stop Docker Compose services"
        echo "  start           Start Docker Compose services"
        echo "  build           Build and copy JAR files only"
        echo "  restart         Restart Docker Compose services"
        echo "  status          Show Docker Compose status"
        echo "  logs            Follow Docker Compose logs"
        echo "  help            Show this help message"
        ;;
    *)
        main
        ;;
esac
