#!/bin/bash
# deploy.sh - Full deployment script with Compose management

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_DIR="$(cd "$REPO_DIR/.." && pwd)"
DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-one"
SERVICE_ASSET_REPO="$BASE_DIR/service-asset"
DOCKER_COMPOSE_FILES=()
read -r -a DOCKER_COMPOSE_CMD <<< "${COMPOSE_CMD:-docker compose}"
if [[ -n "${CONTAINER_CMD:-}" ]]; then
    CONTAINER_RUNTIME_CMD="$CONTAINER_CMD"
elif [[ "${DOCKER_COMPOSE_CMD[0]}" == "podman-compose" ]]; then
    CONTAINER_RUNTIME_CMD="podman"
elif [[ "${DOCKER_COMPOSE_CMD[0]}" == "docker-compose" ]]; then
    CONTAINER_RUNTIME_CMD="docker"
else
    CONTAINER_RUNTIME_CMD="${DOCKER_COMPOSE_CMD[0]}"
fi
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
                echo "Invalid service type: $CONTROLLER_TYPE"
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
DEFAULT_RELEASE_IMAGE_ENV_FILE="$SERVICE_ASSET_REPO/docker-images.env"
if [[ ! -f "$DEFAULT_RELEASE_IMAGE_ENV_FILE" ]] && [[ -f "${HOME:-}/workspace/service-asset/docker-images.env" ]]; then
    DEFAULT_RELEASE_IMAGE_ENV_FILE="${HOME:-}/workspace/service-asset/docker-images.env"
fi
RELEASE_IMAGE_ENV_FILE="${RELEASE_IMAGE_ENV_FILE:-$DEFAULT_RELEASE_IMAGE_ENV_FILE}"
RELEASE_IMAGE_ENV_CONFIGURED=false

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

configure_release_image_env() {
    if [[ "$RELEASE_IMAGE_ENV_CONFIGURED" == "true" ]]; then
        return 0
    fi

    if [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]] &&
       [[ "$CONTROLLER_TYPE" == "rust" ]] &&
       [[ -f "$RELEASE_IMAGE_ENV_FILE" ]]; then
        DOCKER_COMPOSE_CMD+=(--env-file "$RELEASE_IMAGE_ENV_FILE")
    fi

    RELEASE_IMAGE_ENV_CONFIGURED=true
}

load_env_file_var() {
    local name="$1"
    local value=""

    if [[ -n "${!name:-}" ]] || [[ ! -f "$RELEASE_IMAGE_ENV_FILE" ]]; then
        return 0
    fi

    value="$(awk -F= -v key="$name" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$RELEASE_IMAGE_ENV_FILE")"
    if [[ -n "$value" ]]; then
        export "$name=$value"
    fi
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

container_runtime_is_podman() {
    local version_output

    if [[ "$CONTAINER_RUNTIME_CMD" == *podman* ]]; then
        return 0
    fi

    version_output="$("$CONTAINER_RUNTIME_CMD" --version 2>&1 || true)"
    [[ "$version_output" == *podman* || "$version_output" == *Podman* ]]
}

ensure_service_assets() {
    local query_target="$DOCKER_COMPOSE_DIR/hybrid-query/service"
    local command_target="$DOCKER_COMPOSE_DIR/hybrid-command/service"
    local gateway_roots=()

    copy_missing_dir_contents "$query_target" "$SERVICE_ASSET_REPO/hybrid-query" "hybrid-query jars" "*.jar" || exit 1
    copy_missing_dir_contents "$command_target" "$SERVICE_ASSET_REPO/hybrid-command" "hybrid-command jars" "*.jar" || exit 1

    if [ -d "$DOCKER_COMPOSE_DIR/light-gateway-java" ] || [ -d "$DOCKER_COMPOSE_DIR/light-gateway-rust" ]; then
        [ -d "$DOCKER_COMPOSE_DIR/light-gateway-java" ] && gateway_roots+=("$DOCKER_COMPOSE_DIR/light-gateway-java")
        [ -d "$DOCKER_COMPOSE_DIR/light-gateway-rust" ] && gateway_roots+=("$DOCKER_COMPOSE_DIR/light-gateway-rust")
    else
        gateway_roots+=("$DOCKER_COMPOSE_DIR/light-gateway")
    fi

    for gateway_root in "${gateway_roots[@]}"; do
        local gateway_name
        gateway_name="$(basename "$gateway_root")"
        copy_missing_dir_contents "$gateway_root/lightapi/dist" "$SERVICE_ASSET_REPO/lightapi/dist" "$gateway_name lightapi UI assets" "*" "true" || exit 1
        copy_missing_dir_contents "$gateway_root/signin/dist" "$SERVICE_ASSET_REPO/signin/dist" "$gateway_name signin UI assets" "*" "true" || exit 1
    done
}

check_gateway_host_port() {
    local host_port="${LIGHT_GATEWAY_HOST_PORT:-443}"
    local unprivileged_start
    local rootless

    if ! container_runtime_is_podman || [[ ! "$host_port" =~ ^[0-9]+$ ]] || [ "$host_port" -ge 1024 ]; then
        return 0
    fi

    rootless="$("$CONTAINER_RUNTIME_CMD" info --format '{{.Host.Security.Rootless}}' 2>/dev/null || true)"
    if [[ "$rootless" != "true" ]] && [ "$(id -u)" -eq 0 ]; then
        return 0
    fi

    if [ ! -r /proc/sys/net/ipv4/ip_unprivileged_port_start ]; then
        return 0
    fi

    unprivileged_start="$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start)"
    if [[ "$unprivileged_start" =~ ^[0-9]+$ ]] && [ "$host_port" -lt "$unprivileged_start" ]; then
        log_error "Rootless Podman cannot bind host port $host_port while net.ipv4.ip_unprivileged_port_start=$unprivileged_start."
        log_error "To use https://localhost, run:"
        log_error "  printf 'net.ipv4.ip_unprivileged_port_start=443\\n' | sudo tee /etc/sysctl.d/99-rootless-low-ports.conf"
        log_error "  sudo sysctl --system"
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if compose command exists
    if ! "${DOCKER_COMPOSE_CMD[@]}" version &> /dev/null; then
        log_error "${DOCKER_COMPOSE_CMD[*]} not found. Install Docker Compose, or set COMPOSE_CMD=\"podman compose\" after installing podman-compose."
        exit 1
    fi

    if ! "$CONTAINER_RUNTIME_CMD" ps &> /dev/null; then
        log_error "$CONTAINER_RUNTIME_CMD is not available or cannot list containers."
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

    check_gateway_host_port
    ensure_service_assets

    log_success "All prerequisites met"
}

# Stop Compose
stop_docker_compose() {
    log_info "Stopping Compose services..."

    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }

    log_info "Stopping Compose containers..."
    "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" down --timeout 30 --remove-orphans

    log_success "Compose services stopped"
}

# Start Compose
start_docker_compose() {
    log_info "Starting Compose services..."

    check_gateway_host_port || exit 1
    ensure_service_assets || exit 1

    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }

    # Start services in detached mode
    log_info "Starting services..."
    if "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" up -d --build; then
        log_success "Compose services started"

        # Show status
        log_info "Current service status:"
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps

        # Tail logs for a few seconds to show startup
        log_info "Showing startup logs (tail for 10 seconds)..."
        timeout 10 "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" logs -f --tail=10 2>/dev/null || true
    else
        log_error "Failed to start Compose services"
        return 1
    fi
}

list_compose_services() {
    "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" config --services 2>/dev/null ||
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps --services
}

service_is_running() {
    local service="$1"
    local container_ids
    local container_id
    local running

    container_ids="$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps -q "$service" 2>/dev/null || true)"
    [ -n "$container_ids" ] || return 1

    for container_id in $container_ids; do
        running="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Running}}' "$container_id" 2>/dev/null || true)"
        if [[ "$running" == "true" ]]; then
            return 0
        fi
    done

    return 1
}

get_event_store_count() {
    "$CONTAINER_RUNTIME_CMD" exec postgres psql -U postgres -d configserver -tAc "select count(*) from event_store_t;"
}

default_event_import_network() {
    local network=""
    network="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{range $name, $_ := .NetworkSettings.Networks}}{{println $name}}{{end}}' postgres 2>/dev/null | head -n 1 || true)"
    if [[ -n "$network" ]]; then
        printf '%s\n' "$network"
    else
        printf '%s_default\n' "${COMPOSE_PROJECT_NAME:-$(basename "$DOCKER_COMPOSE_DIR")}"
    fi
}

wait_for_event_store_count() {
    local max_attempts="${EVENT_IMPORT_DB_READY_ATTEMPTS:-30}"
    local interval="${EVENT_IMPORT_DB_READY_INTERVAL:-5}"
    local attempt=1
    local count=""

    while [ "$attempt" -le "$max_attempts" ]; do
        count="$(get_event_store_count 2>/dev/null | tr -d '[:space:]' || true)"
        if [[ "$count" =~ ^[0-9]+$ ]]; then
            printf '%s\n' "$count"
            return 0
        fi

        sleep "$interval"
        attempt=$((attempt + 1))
    done

    return 1
}

run_container_event_importer() {
    local event_file="$1"
    local importer_image="$2"
    shift 2
    local event_dir
    local event_name
    local import_network
    local db_jdbc_url
    local event_mount

    event_dir="$(cd "$(dirname "$event_file")" && pwd)"
    event_name="$(basename "$event_file")"
    import_network="${EVENT_IMPORT_NETWORK:-$(default_event_import_network)}"
    db_jdbc_url="${EVENT_IMPORT_DB_JDBC_URL:-jdbc:postgresql://postgres:5432/configserver}"
    if container_runtime_is_podman; then
        log_info "Streaming $event_file to event-importer over stdin"
        "$CONTAINER_RUNTIME_CMD" run --rm -i \
            --network "$import_network" \
            -e DB_JDBC_URL="$db_jdbc_url" \
            -e DB_USERNAME="${EVENT_IMPORT_DB_USERNAME:-postgres}" \
            -e DB_PASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" \
            -e DB_MAXIMUM_POOL_SIZE="${EVENT_IMPORT_DB_MAXIMUM_POOL_SIZE:-3}" \
            "$importer_image" \
            --filename "/dev/stdin" \
            "$@" < "$event_file"
        return $?
    fi
    event_mount="$event_dir:/events:ro"

    log_info "Running $CONTAINER_RUNTIME_CMD event-importer image $importer_image on network $import_network"
    "$CONTAINER_RUNTIME_CMD" run --rm \
        --network "$import_network" \
        -v "$event_mount" \
        -e DB_JDBC_URL="$db_jdbc_url" \
        -e DB_USERNAME="${EVENT_IMPORT_DB_USERNAME:-postgres}" \
        -e DB_PASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" \
        -e DB_MAXIMUM_POOL_SIZE="${EVENT_IMPORT_DB_MAXIMUM_POOL_SIZE:-3}" \
        "$importer_image" \
        --filename "/events/$event_name" \
        "$@"
}

run_local_event_importer() {
    local event_file="$1"
    local database_url="$2"
    shift 2
    local importer_cmd=()

    if [[ -n "${EVENT_IMPORTER_CMD:-}" ]]; then
        read -r -a importer_cmd <<< "$EVENT_IMPORTER_CMD"
    elif [[ -x "$SERVICE_ASSET_REPO/importer-rust.sh" && -x "$SERVICE_ASSET_REPO/rust/linux/importer" ]]; then
        importer_cmd=("./importer-rust.sh")
    elif [[ -x "$SERVICE_ASSET_REPO/importer.sh" ]]; then
        importer_cmd=("./importer.sh")
    else
        log_error "No executable importer found in $SERVICE_ASSET_REPO"
        return 1
    fi

    log_info "Running local event importer: ${importer_cmd[*]}"
    (
        cd "$SERVICE_ASSET_REPO" || exit 1
        export DATABASE_URL="$database_url"
        "${importer_cmd[@]}" --filename "$event_file" "$@"
    )
}

import_events() {
    local import_mode="${IMPORT_EVENTS:-false}"
    local import_mode_lower="${import_mode,,}"
    local event_file="$SERVICE_ASSET_REPO/events.json"
    local database_url="${EVENT_IMPORT_DATABASE_URL:-postgres://postgres:secret@localhost:5432/configserver}"
    local import_runner="${EVENT_IMPORT_RUNNER:-container}"
    local import_runner_lower
    local importer_image
    local extra_args=()
    local event_count=""

    case "$import_mode_lower" in
        false|no|0|"")
            log_info "Event import skipped. Set IMPORT_EVENTS=auto or IMPORT_EVENTS=true to import service-asset events."
            return 0
            ;;
        auto|true|yes|1|force)
            ;;
        *)
            log_error "Invalid IMPORT_EVENTS value: $import_mode. Use false, auto, true, or force."
            return 1
            ;;
    esac

    if [ ! -d "$SERVICE_ASSET_REPO" ]; then
        log_error "service-asset repo not found at $SERVICE_ASSET_REPO"
        return 1
    fi

    if [[ -n "${EVENT_IMPORT_FILE:-}" ]]; then
        log_error "EVENT_IMPORT_FILE is not supported. Replace $event_file before starting deploy-local.sh if you need custom events."
        return 1
    fi

    if [ ! -f "$event_file" ]; then
        log_error "Event import file not found: $event_file"
        return 1
    fi

    if event_count="$(wait_for_event_store_count)"; then
        if [[ "$import_mode_lower" == "auto" && "$event_count" -gt 0 ]]; then
            log_info "Event store already has $event_count rows; skipping automatic import."
            return 0
        fi
    elif [[ "$import_mode_lower" == "auto" ]]; then
        log_warning "Cannot read event_store_t count; skipping automatic event import."
        return 0
    else
        log_error "Cannot read event_store_t count before event import."
        return 1
    fi

    if [[ -n "${EVENT_IMPORT_ARGS:-}" ]]; then
        read -r -a extra_args <<< "$EVENT_IMPORT_ARGS"
    fi

    import_runner_lower="${import_runner,,}"
    load_env_file_var EVENT_IMPORTER_IMAGE
    importer_image="${EVENT_IMPORTER_IMAGE:-networknt/event-importer:latest}"

    log_info "Importing events from $event_file"
    case "$import_runner_lower" in
        container|docker|podman)
            run_container_event_importer "$event_file" "$importer_image" "${extra_args[@]}"
            ;;
        local|host)
            run_local_event_importer "$event_file" "$database_url" "${extra_args[@]}"
            ;;
        auto)
            if ! run_container_event_importer "$event_file" "$importer_image" "${extra_args[@]}"; then
                log_warning "Container event import failed; trying local importer fallback"
                run_local_event_importer "$event_file" "$database_url" "${extra_args[@]}"
            fi
            ;;
        *)
            log_error "Invalid EVENT_IMPORT_RUNNER value: $import_runner. Use container, local, or auto."
            return 1
            ;;
    esac
    log_success "Event import completed"
}

# Verify Compose services are running
verify_services() {
    log_info "Verifying Compose services are running..."

    cd "$DOCKER_COMPOSE_DIR" || return 1

    local max_attempts=30
    local attempt=1

    local services=()
    mapfile -t services < <(list_compose_services)

    while [ $attempt -le $max_attempts ]; do
        log_info "Service running check attempt $attempt of $max_attempts..."

        local total_services="${#services[@]}"
        local running_services=0
        local pending_services=()

        for service in "${services[@]}"; do
            [ -n "$service" ] || continue
            if service_is_running "$service"; then
                running_services=$((running_services + 1))
            else
                pending_services+=("$service")
            fi
        done

        if [ "$running_services" -eq "$total_services" ] && [ "$total_services" -gt 0 ]; then
            log_success "All $total_services services are running"
            return 0
        fi

        if [ "${#pending_services[@]}" -gt 0 ]; then
            log_info "$running_services of $total_services services running; waiting for: ${pending_services[*]}"
        else
            log_info "$running_services of $total_services services running..."
        fi
        sleep 10
        attempt=$((attempt + 1))
    done

    log_warning "Some services are not running after $max_attempts attempts"
    log_info "Current service status:"
    "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps
    return 1
}

# Show deployment summary
show_summary() {
    log_info "=== Deployment Summary ==="
    log_info "Log file: $LOG_FILE"
    log_info "Compose command: ${DOCKER_COMPOSE_CMD[*]}"
    log_info "Container command: $CONTAINER_RUNTIME_CMD"
    log_info "Compose directory: $DOCKER_COMPOSE_DIR"
    if [ -n "$CONTROLLER_TYPE" ]; then
        log_info "Service type: $CONTROLLER_TYPE"
    fi

    cd "$DOCKER_COMPOSE_DIR" && {
        log_info "Running containers:"
        list_compose_services | while read -r service; do
            if service_is_running "$service"; then
                log_info "  - $service: running"
            else
                log_info "  - $service: not running"
            fi
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
        log_info "Selected service type: $CONTROLLER_TYPE"
    fi

    # Step 1: Check prerequisites
    check_prerequisites

    # Step 2: Stop Compose
    stop_docker_compose

    # Step 3: Start Compose
    if ! start_docker_compose; then
        log_error "Failed to start Compose"
        exit 1
    fi

    # Step 4: Import events if requested. Some services bootstrap config from
    # imported events, so import before waiting for every service to stay up.
    if [[ -z "${IMPORT_EVENTS+x}" ]]; then
        log_info "IMPORT_EVENTS not set; defaulting to auto for full deployment."
        IMPORT_EVENTS=auto
    fi
    import_events

    # Step 5: Verify services
    verify_services

    # Step 6: Show summary
    show_summary

    log_success "Deployment completed successfully!"
    log_info "To view logs: ${DOCKER_COMPOSE_CMD[*]} ${DOCKER_COMPOSE_FILES[*]} logs -f"
}

# Handle script arguments
configure_release_image_env

case "${1:-}" in
    "stop")
        stop_docker_compose
        ;;
    "start")
        start_docker_compose
        import_events
        ;;
    "restart")
        stop_docker_compose
        sleep 2
        start_docker_compose
        import_events
        ;;
    "status")
        cd "$DOCKER_COMPOSE_DIR" && "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps
        ;;
    "verify")
        verify_services
        ;;
    "logs")
        cd "$DOCKER_COMPOSE_DIR" && "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" logs -f --tail=100
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [config] [service-type] [command]"
        echo ""
        echo "Config (optional):"
        echo "  kafka           Use Kafka configuration (default)"
        echo "  pg              Use Postgres configuration"
        echo "  lt              Use Light Postgres configuration (one hybrid-query)"
        echo ""
        echo "Service type (optional, pg and lt only):"
        echo "  java            Use Java service overrides (default for pg and lt)"
        echo "  rust            Use Rust service overrides"
        echo ""
        echo "Commands:"
        echo "  (no command)    Full deployment (stop, start, optional event import)"
        echo "  stop            Stop Compose services"
        echo "  start           Start Compose services"
        echo "  restart         Restart Compose services"
        echo "  status          Show Compose status"
        echo "  verify          Wait until every Compose service has a running container"
        echo "  logs            Follow Compose logs"
        echo "  help            Show this help message"
        echo ""
        echo "Environment:"
        echo "  COMPOSE_CMD=\"podman compose\"     Use Podman Compose instead of the default docker compose"
        echo "  CONTAINER_CMD=podman              Container command for exec/inspect checks"
        echo "  LIGHT_GATEWAY_HOST_PORT=443       Gateway host port (default 443)"
        echo "  IMPORT_EVENTS=auto                Import service-asset/events.json only when event_store_t is empty (default for full deployment)"
        echo "  IMPORT_EVENTS=false               Skip event import"
        echo "  IMPORT_EVENTS=true                Import service-asset/events.json even when rows already exist"
        echo "  EVENT_IMPORT_RUNNER=container     Use container, local, or auto importer runner"
        echo "  EVENT_IMPORTER_IMAGE=...          Container image for event import"
        echo "  EVENT_IMPORT_NETWORK=...          Override Compose network for event importer"
        echo "  EVENT_IMPORTER_CMD=...            Override local importer command when EVENT_IMPORT_RUNNER=local"
        ;;
    *)
        main
        ;;
esac
