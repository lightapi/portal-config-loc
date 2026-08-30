#!/bin/bash
# deploy.sh - Full deployment script with Compose management

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_DIR="$(cd "$REPO_DIR/.." && pwd)"
DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-one"
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

if [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-pg" ]]; then
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
elif [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]]; then
    CONTROLLER_TYPE="rust"
    case "${1:-}" in
        rust)
            shift
            ;;
        java)
            echo "The all-in-lt Java service profile has been removed; use the Rust stack."
            exit 1
            ;;
        ""|stop|start|restart|status|logs|provisioner-start|provisioner-stop|provisioner-status|help|-h|--help)
            ;;
        *)
            echo "Invalid service type: $1"
            echo "Usage: $0 lt [rust] [command]"
            exit 1
            ;;
    esac
fi

LOG_FILE="/tmp/deploy_$(date +%Y%m%d_%H%M%S).log"
BUILD_SCRIPT="$BASE_DIR/copy-service-local.sh"
RELEASE_STATE_DIR="${RELEASE_STATE_DIR:-$BASE_DIR/.release-state}"
LIGHT_PORTAL_ASSET_BASE_URL="${LIGHT_PORTAL_ASSET_BASE_URL:-https://cdn.networknt.com}"
RELEASE_ASSET_CACHE_DIR="${RELEASE_ASSET_CACHE_DIR:-$RELEASE_STATE_DIR/assets}"
REFRESH_RELEASE_ASSETS="${REFRESH_RELEASE_ASSETS:-false}"
RELEASE_IMAGE_ENV_CACHE="${RELEASE_IMAGE_ENV_CACHE:-$RELEASE_STATE_DIR/docker-images.env}"
RELEASE_IMAGE_ENV_FILE="${RELEASE_IMAGE_ENV_FILE:-$RELEASE_IMAGE_ENV_CACHE}"
RELEASE_IMAGE_ENV_URL="${RELEASE_IMAGE_ENV_URL:-$LIGHT_PORTAL_ASSET_BASE_URL/docker-images.env}"
RELEASE_IMAGE_ENV_CONFIGURED=false
RELEASE_IMAGE_ENV_FETCHED=false
LIGHT_PORTAL_ENV_FILE="${LIGHT_PORTAL_ENV_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/lightapi/light-portal.env}"
R2_ENDPOINT_URL="${R2_ENDPOINT_URL:-https://033b143ffb81eda015ca350680ac5f28.r2.cloudflarestorage.com}"

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

ensure_release_image_env_file() {
    if [[ "$RELEASE_IMAGE_ENV_FETCHED" == "true" ]]; then
        return 0
    fi
    RELEASE_IMAGE_ENV_FETCHED=true

    if [[ -f "$RELEASE_IMAGE_ENV_FILE" ]]; then
        return 0
    fi

    if [[ -n "${RELEASE_IMAGE_ENV_URL:-}" ]]; then
        mkdir -p "$(dirname "$RELEASE_IMAGE_ENV_FILE")"
        log_info "Downloading release image env file from $RELEASE_IMAGE_ENV_URL"
        if curl -fsSL "$RELEASE_IMAGE_ENV_URL" -o "$RELEASE_IMAGE_ENV_FILE"; then
            return 0
        fi
        log_warning "Failed to download release image env file from $RELEASE_IMAGE_ENV_URL"
    fi

    if [[ -n "${RELEASE_IMAGE_ENV_S3_URI:-}" ]]; then
        if command -v aws >/dev/null 2>&1; then
            mkdir -p "$(dirname "$RELEASE_IMAGE_ENV_FILE")"
            log_info "Downloading release image env file from $RELEASE_IMAGE_ENV_S3_URI"
            if aws --endpoint-url "$R2_ENDPOINT_URL" s3 cp "$RELEASE_IMAGE_ENV_S3_URI" "$RELEASE_IMAGE_ENV_FILE"; then
                return 0
            fi
            log_warning "Failed to download release image env file from $RELEASE_IMAGE_ENV_S3_URI"
        else
            log_warning "aws command not found; cannot download $RELEASE_IMAGE_ENV_S3_URI"
        fi
    fi

    return 1
}

configure_release_image_env() {
    if [[ "$RELEASE_IMAGE_ENV_CONFIGURED" == "true" ]]; then
        return 0
    fi

    ensure_release_image_env_file || true

    if [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]] &&
       [[ "$CONTROLLER_TYPE" == "rust" ]] &&
       [[ -f "$RELEASE_IMAGE_ENV_FILE" ]]; then
        DOCKER_COMPOSE_CMD+=(--env-file "$RELEASE_IMAGE_ENV_FILE")
    fi

    RELEASE_IMAGE_ENV_CONFIGURED=true
}

configure_light_portal_env() {
    if [[ -f "$LIGHT_PORTAL_ENV_FILE" ]]; then
        DOCKER_COMPOSE_CMD+=(--env-file "$LIGHT_PORTAL_ENV_FILE")
        log_info "Using local Portal environment file: $LIGHT_PORTAL_ENV_FILE"
    fi
}

configure_local_reasoning_seal_key() {
    local configured_value=""
    local secret_file="$RELEASE_STATE_DIR/llm-reasoning-seal-key"
    local temporary_file="${secret_file}.tmp"

    if [[ -n "${LLM_REASONING_SEAL_KEY:-}" ]]; then
        return 0
    fi
    if [[ -f "$LIGHT_PORTAL_ENV_FILE" ]]; then
        configured_value="$(awk -F= '$1 == "LLM_REASONING_SEAL_KEY" { sub(/^[^=]*=/, ""); print; exit }' "$LIGHT_PORTAL_ENV_FILE")"
        if [[ -n "$configured_value" ]]; then
            export LLM_REASONING_SEAL_KEY="$configured_value"
            return 0
        fi
    fi

    mkdir -p "$RELEASE_STATE_DIR"
    if [[ -s "$secret_file" ]]; then
        export LLM_REASONING_SEAL_KEY="$(<"$secret_file")"
        return 0
    fi
    if "$CONTAINER_RUNTIME_CMD" inspect llm-gateway >/dev/null 2>&1; then
        configured_value="$("$CONTAINER_RUNTIME_CMD" inspect llm-gateway \
            --format '{{range .Config.Env}}{{println .}}{{end}}' \
            | awk -F= '$1 == "LLM_REASONING_SEAL_KEY" { sub(/^[^=]*=/, ""); print; exit }')"
        if [[ -n "$configured_value" ]]; then
            umask 077
            printf '%s' "$configured_value" > "$temporary_file"
            mv "$temporary_file" "$secret_file"
            chmod 600 "$secret_file"
            export LLM_REASONING_SEAL_KEY="$configured_value"
            log_info "Preserved the running local LLM reasoning seal key in $secret_file"
            return 0
        fi
    fi

    umask 077
    openssl rand -base64 32 | tr '+/' '-_' | tr -d '=\n' > "$temporary_file"
    mv "$temporary_file" "$secret_file"
    chmod 600 "$secret_file"
    log_info "Generated a persistent local LLM reasoning seal key in $secret_file"
    export LLM_REASONING_SEAL_KEY="$(<"$secret_file")"
}

configure_local_runtime_identity() {
    export LOCAL_UID="${LOCAL_UID:-$(id -u)}"
    export LOCAL_GID="${LOCAL_GID:-$(id -g)}"
    export PORTAL_WORKSPACE_ROOT="${PORTAL_WORKSPACE_ROOT:-$BASE_DIR}"
    log_info "Using local runtime identity: ${LOCAL_UID}:${LOCAL_GID}"
}

prepare_operational_database_secret() {
    local prepare_script
    local secret_dir
    local runtime_uid="${OPERATIONAL_RUNTIME_UID:-999}"
    local runtime_gid="${OPERATIONAL_RUNTIME_GID:-999}"

    [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]] || return 0
    case "${1:-}" in
        stop|status|logs) return 0 ;;
    esac

    prepare_script="$DOCKER_COMPOSE_DIR/postgres-db/operations/bin/prepare-operational-secret.sh"
    secret_dir="$DOCKER_COMPOSE_DIR/postgres-db/secrets"
    [[ -x "$prepare_script" ]] || {
        log_error "Operational database secret initializer is missing: $prepare_script"
        return 1
    }

    mkdir -p "$secret_dir"
    "$CONTAINER_RUNTIME_CMD" run --rm --user 0:0 \
        -v "$secret_dir:/runtime-secrets:Z" \
        timescale/timescaledb:latest-pg17 \
        chown -R "${LOCAL_UID}:${LOCAL_GID}" /runtime-secrets || {
        log_error "Failed to make operational secrets available for validation"
        return 1
    }

    OPERATIONAL_SECRET_DIR="$secret_dir" \
        "$prepare_script" >/dev/null || {
        log_error "Failed to prepare operational database secrets"
        return 1
    }
    "$CONTAINER_RUNTIME_CMD" run --rm --user 0:0 \
        -v "$secret_dir:/runtime-secrets:Z" \
        timescale/timescaledb:latest-pg17 \
        /bin/sh -ec 'find /runtime-secrets -mindepth 1 -maxdepth 1 -type f \( -name ".operations-*" -o -name "*-database-url" -o -name "a2a-authorized-context-key" \) -exec chown "$1:$2" {} +' \
        runtime-secret-owner "$runtime_uid" "$runtime_gid" || {
        log_error "Failed to assign operational secrets to the runtime identity"
        return 1
    }
    log_info "Operational database URL file is ready (content redacted)"
}

operational_provisioner_paths() {
    OPERATIONAL_PROVISIONER_SCRIPT="$DOCKER_COMPOSE_DIR/postgres-db/operations/bin/operational-store-provisioner.sh"
    OPERATIONAL_PROVISIONER_TOKEN_FILE="${OPERATIONAL_PROVISIONER_TOKEN_FILE:-$RELEASE_STATE_DIR/operational-store-provisioner-token}"
    OPERATIONAL_PROVISIONER_CONTROL_URL_FILE="${OPERATIONAL_PROVISIONER_CONTROL_URL_FILE:-$RELEASE_STATE_DIR/operational-store-control-database-url}"
    OPERATIONAL_PROVISIONER_SECRET_ROOT="${OPERATIONAL_PROVISIONER_SECRET_ROOT:-$RELEASE_STATE_DIR/operational-store-bindings}"
}

prepare_operational_provisioner_runtime() {
    local temporary_file

    [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]] || return 0
    operational_provisioner_paths
    mkdir -p "$RELEASE_STATE_DIR" "$OPERATIONAL_PROVISIONER_SECRET_ROOT"
    chmod 700 "$OPERATIONAL_PROVISIONER_SECRET_ROOT"
    temporary_file="${OPERATIONAL_PROVISIONER_CONTROL_URL_FILE}.tmp"
    umask 077
    printf '%s' 'postgresql://postgres:secret@postgres:5432/configserver?options=-csearch_path%3Dconfigserver' > "$temporary_file"
    mv "$temporary_file" "$OPERATIONAL_PROVISIONER_CONTROL_URL_FILE"
    chmod 600 "$OPERATIONAL_PROVISIONER_CONTROL_URL_FILE"
}

stop_operational_store_provisioner() {
    [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]] || return 0
    cd "$DOCKER_COMPOSE_DIR" || return 1
    if [[ -n "$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" --profile operational-store-provisioning ps -q operational-store-provisioner 2>/dev/null)" ]]; then
        log_info "Stopping operational-store provisioner"
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" --profile operational-store-provisioning stop operational-store-provisioner
    fi
}

start_operational_store_provisioner() {
    local container_id=""
    local state=""

    [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]] || return 0
    prepare_operational_provisioner_runtime
    [[ -x "$OPERATIONAL_PROVISIONER_SCRIPT" ]] || {
        log_error "Operational-store provisioner is missing: $OPERATIONAL_PROVISIONER_SCRIPT"
        return 1
    }
    if [[ ! -s "$OPERATIONAL_PROVISIONER_TOKEN_FILE" ]]; then
        log_warning "Operational-store provisioner is not started because its token file is missing: $OPERATIONAL_PROVISIONER_TOKEN_FILE"
        log_warning "Create a client-credentials service token with only the operational-store-provisioner role, store it with mode 600, then run deploy-local.sh lt start."
        return 0
    fi
    chmod 600 "$OPERATIONAL_PROVISIONER_TOKEN_FILE"
    cd "$DOCKER_COMPOSE_DIR" || return 1
    log_info "Starting operational-store provisioner Compose service"
    "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" --profile operational-store-provisioning \
        up -d --build operational-store-provisioner || return 1
    sleep 2
    container_id="$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" --profile operational-store-provisioning ps -q operational-store-provisioner)"
    state="$([[ -n "$container_id" ]] && "$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
    if [[ "$state" != "running" ]]; then
        log_error "Operational-store provisioner failed to stay running"
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" --profile operational-store-provisioning logs --tail=80 operational-store-provisioner || true
        return 1
    fi
    log_success "Operational-store provisioner Compose service is running"
}

load_env_file_var() {
    local name="$1"
    local value=""

    ensure_release_image_env_file || true

    if [[ -n "${!name:-}" ]] || [[ ! -f "$RELEASE_IMAGE_ENV_FILE" ]]; then
        return 0
    fi

    value="$(awk -F= -v key="$name" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$RELEASE_IMAGE_ENV_FILE")"
    if [[ -n "$value" ]]; then
        export "$name=$value"
    fi
}

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

download_file() {
    local url="$1"
    local dest="$2"
    local tmp="${dest}.tmp"

    mkdir -p "$(dirname "$dest")"
    log_info "Downloading $url"
    curl -fsSL "$url" -o "$tmp"
    mv "$tmp" "$dest"
}

ensure_archive() {
    local archive_name="$1"
    local archive_path="$RELEASE_ASSET_CACHE_DIR/$archive_name"

    if [[ -f "$archive_path" ]] && ! is_true "$REFRESH_RELEASE_ASSETS"; then
        return 0
    fi

    download_file "$LIGHT_PORTAL_ASSET_BASE_URL/$archive_name" "$archive_path"
}

target_has_contents() {
    local target_dir="$1"
    local file_pattern="${2:-*}"

    [[ -d "$target_dir" ]] || return 1
    if [[ "$file_pattern" == "*" ]]; then
        find "$target_dir" -mindepth 1 ! -name '.gitkeep' -print -quit | grep -q .
        return $?
    fi
    find "$target_dir" -maxdepth 1 -type f -name "$file_pattern" | grep -q .
}

extract_archive_if_missing() {
    local archive_name="$1"
    local target_dir="$2"
    local asset_name="$3"
    local file_pattern="${4:-*}"
    local replace_on_refresh="${5:-false}"
    local archive_path
    local preserve_gitkeep=false
    local replace_target=false

    if is_true "$REFRESH_RELEASE_ASSETS" && is_true "$replace_on_refresh"; then
        replace_target=true
    fi

    if [[ "$replace_target" != "true" ]] && target_has_contents "$target_dir" "$file_pattern"; then
        log_info "$asset_name already present in $target_dir"
        return 0
    fi

    command -v curl >/dev/null 2>&1 || {
        log_error "curl is required to download $asset_name from $LIGHT_PORTAL_ASSET_BASE_URL"
        return 1
    }
    command -v unzip >/dev/null 2>&1 || {
        log_error "unzip is required to extract $asset_name from $archive_name"
        return 1
    }

    archive_path="$RELEASE_ASSET_CACHE_DIR/$archive_name"
    ensure_archive "$archive_name" || return 1
    log_info "Extracting $asset_name from $archive_path to $target_dir"
    if [[ -f "$target_dir/.gitkeep" ]]; then
        preserve_gitkeep=true
    fi
    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    unzip -q "$archive_path" -d "$target_dir"
    if [[ "$preserve_gitkeep" == "true" ]]; then
        : > "$target_dir/.gitkeep"
    fi
}

ensure_event_file() {
    local event_file="$RELEASE_ASSET_CACHE_DIR/events.json"
    local archive_path

    if [[ -f "$event_file" ]] && ! is_true "$REFRESH_RELEASE_ASSETS"; then
        return 0
    fi

    command -v curl >/dev/null 2>&1 || {
        log_error "curl is required to download events.zip from $LIGHT_PORTAL_ASSET_BASE_URL"
        return 1
    }
    command -v unzip >/dev/null 2>&1 || {
        log_error "unzip is required to extract events.json from events.zip"
        return 1
    }

    archive_path="$RELEASE_ASSET_CACHE_DIR/events.zip"
    ensure_archive events.zip || return 1
    log_info "Extracting events.json from $archive_path"
    mkdir -p "$RELEASE_ASSET_CACHE_DIR"
    unzip -p "$archive_path" events.json > "$event_file.tmp"
    mv "$event_file.tmp" "$event_file"
}

container_runtime_is_podman() {
    local version_output

    if [[ "$CONTAINER_RUNTIME_CMD" == *podman* ]]; then
        return 0
    fi

    version_output="$("$CONTAINER_RUNTIME_CMD" --version 2>&1 || true)"
    [[ "$version_output" == *podman* || "$version_output" == *Podman* ]]
}

ensure_release_assets() {
    local query_target="$DOCKER_COMPOSE_DIR/hybrid-query/service"
    local command_target="$DOCKER_COMPOSE_DIR/hybrid-command/service"
    local gateway_roots=()

    extract_archive_if_missing "hybrid-query.zip" "$query_target" "hybrid-query jars" "*.jar" true || exit 1
    extract_archive_if_missing "hybrid-command.zip" "$command_target" "hybrid-command jars" "*.jar" true || exit 1

    if [ -d "$DOCKER_COMPOSE_DIR/light-gateway-rust" ]; then
        gateway_roots+=("$DOCKER_COMPOSE_DIR/light-gateway-rust")
    else
        gateway_roots+=("$DOCKER_COMPOSE_DIR/light-gateway")
    fi

    for gateway_root in "${gateway_roots[@]}"; do
        local gateway_name
        gateway_name="$(basename "$gateway_root")"
        extract_archive_if_missing "lightapi.zip" "$gateway_root/lightapi" "$gateway_name lightapi UI assets" "*" || exit 1
        extract_archive_if_missing "signin.zip" "$gateway_root/signin" "$gateway_name signin UI assets" "*" || exit 1
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
    ensure_release_assets

    log_success "All prerequisites met"
}

# Stop Compose
stop_docker_compose() {
    log_info "Stopping Compose services..."

    stop_operational_store_provisioner

    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }

    log_info "Stopping Compose containers..."
    local down_args=("--timeout" "30" "--remove-orphans")
    if [[ "${CLEAN_VOLUMES:-false}" == "true" ]]; then
        down_args+=("-v")
        log_info "Volumes will be removed (-v)"
    fi
    "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" down "${down_args[@]}"

    log_success "Compose services stopped"
}

# Start Compose
start_docker_compose() {
    log_info "Starting Compose services..."

    check_gateway_host_port || exit 1
    ensure_release_assets || exit 1

    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }

    # Start services in detached mode
    log_info "Starting services..."
    if "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" up -d --build; then
        log_info "Compose services were created; qualifying required runtime services..."

        start_operational_store_provisioner || return 1
        validate_operational_property_projection || return 1
        wait_for_required_runtime_services || return 1
        log_success "Compose services started and passed runtime qualification"

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

required_runtime_services() {
    if [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]]; then
        printf '%s\n' \
            postgres \
            light-oauth \
            controller \
            config-server \
            hybrid-command \
            hybrid-query \
            portal-service \
            light-gateway \
            llm-gateway \
            light-workflow \
            demo-customer-profile-api \
            demo-offer-decision-api \
            demo-insurance-claim-mcp-server \
            light-agent \
            light-agent-advisor \
            light-agent-tech-support \
            light-knowledge-admin \
            light-knowledge \
            light-knowledge-worker
        return 0
    fi

    # Other local profiles do not currently declare a separate qualification
    # contract. Preserve their existing startup behavior.
    return 0
}

log_required_service_diagnostics() {
    local service="$1"
    local container_id="${2:-}"
    local status="unknown"

    if [[ -n "$container_id" ]]; then
        status="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}} exit={{.State.ExitCode}}' "$container_id" 2>/dev/null || true)"
    fi
    log_error "Required service $service failed runtime qualification (status: ${status:-unknown})"
    "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" logs --tail=80 "$service" 2>&1 | tee -a "$LOG_FILE" || true
}

wait_for_required_runtime_services() {
    local timeout_seconds="${RUNTIME_QUALIFICATION_TIMEOUT_SECONDS:-120}"
    local interval="${RUNTIME_QUALIFICATION_INTERVAL_SECONDS:-2}"
    local elapsed=0
    local service=""
    local container_id=""
    local state=""
    local health=""
    local pending=()
    local services=()

    mapfile -t services < <(required_runtime_services)
    if ((${#services[@]} == 0)); then
        return 0
    fi
    if [[ ! "$timeout_seconds" =~ ^[1-9][0-9]*$ || ! "$interval" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Runtime qualification timeout and interval must be positive integers"
        return 1
    fi

    while [ "$elapsed" -le "$timeout_seconds" ]; do
        pending=()
        for service in "${services[@]}"; do
            container_id="$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps -a -q "$service" 2>/dev/null | head -n 1 || true)"
            if [[ -z "$container_id" ]]; then
                pending+=("$service(absent)")
                continue
            fi

            state="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
            health="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container_id" 2>/dev/null || true)"
            case "$state" in
                exited|dead|removing)
                    log_required_service_diagnostics "$service" "$container_id"
                    return 1
                    ;;
                running)
                    case "$health" in
                        ""|healthy) ;;
                        unhealthy)
                            log_required_service_diagnostics "$service" "$container_id"
                            return 1
                            ;;
                        *) pending+=("$service($health)") ;;
                    esac
                    ;;
                *) pending+=("$service(${state:-unknown})") ;;
            esac
        done

        if ((${#pending[@]} == 0)); then
            return 0
        fi
        if [ $((elapsed % 10)) -eq 0 ]; then
            log_info "Waiting for runtime qualification (${elapsed}s/${timeout_seconds}s): ${pending[*]}"
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    log_error "Required runtime services did not become ready within ${timeout_seconds} seconds: ${pending[*]}"
    for service in "${services[@]}"; do
        container_id="$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps -a -q "$service" 2>/dev/null | head -n 1 || true)"
        state="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
        health="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container_id" 2>/dev/null || true)"
        if [[ "$state" != "running" || ( -n "$health" && "$health" != "healthy" ) ]]; then
            log_required_service_diagnostics "$service" "$container_id"
        fi
    done
    return 1
}

validate_operational_property_projection() {
    local required_property_count="15"
    local agent_snapshot_count="0"
    local catalog_property_count="0"
    local catalog_path="${OPERATIONAL_PROPERTY_CATALOG_FILE:-$BASE_DIR/implementation/light-portal/development-database-topology/phase7/operational-store-config-metadata.cloud.json}"
    local required_properties="'operationalStore.contractVersion','operationalStore.bindingId','operationalStore.bindingDigest','operationalStore.profileId','operationalStore.deploymentProfile','operationalStore.scopeKind','operationalStore.scopeId','operationalStore.hostId','operationalStore.environment','operationalStore.serviceOwner','operationalStore.schema','operationalStore.minimumSchemaVersion','operationalStore.expectedDatabase','operationalStore.databaseUrlFile','operationalStore.credentialGeneration'"

    [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]] || return 0
    wait_for_postgres_ready || {
        log_error "Cannot validate operational-store properties because Postgres is not ready"
        return 1
    }

    catalog_property_count="$("$CONTAINER_RUNTIME_CMD" exec -e PGPASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" postgres \
        psql -h localhost -U postgres -d configserver -tAc \
        "SELECT count(DISTINCT property_name) FROM configserver.config_property_t WHERE active AND property_name IN ($required_properties);" \
        2>/dev/null | tr -d '[:space:]' || true)"
    if [[ ! "$catalog_property_count" =~ ^[0-9]+$ ]]; then
        log_error "Cannot query the operational-store property catalog in configserver.config_property_t"
        return 1
    fi
    if [[ "$catalog_property_count" != "$required_property_count" ]]; then
        log_error "Operational-store property catalog is incomplete (${catalog_property_count:-0}/${required_property_count} required Agent properties)."
        log_error "Import $catalog_path, assign the complete catalog to each Agent product version, and regenerate the Agent instance snapshots."
        return 1
    fi

    agent_snapshot_count="$("$CONTAINER_RUNTIME_CMD" exec -e PGPASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" postgres \
        psql -h localhost -U postgres -d configserver -tAc \
        "SELECT count(*) FROM (SELECT s.service_id FROM configserver.config_snapshot_t s JOIN configserver.config_snapshot_property_t p ON p.snapshot_id = s.snapshot_id WHERE s.current AND s.service_id IN ('com.networknt.agent.account-1.0.0','com.networknt.agent.advisor-1.0.0','com.networknt.agent.tech-support-1.0.0') AND p.property_name IN ($required_properties) AND NULLIF(btrim(p.property_value), '') IS NOT NULL GROUP BY s.service_id HAVING count(DISTINCT p.property_name) = $required_property_count) ready_agent_snapshots;" \
        2>/dev/null | tr -d '[:space:]' || true)"
    if [[ ! "$agent_snapshot_count" =~ ^[0-9]+$ ]]; then
        log_error "Cannot query current Agent snapshot properties"
        return 1
    fi
    if [[ "$agent_snapshot_count" != "3" ]]; then
        log_error "Only ${agent_snapshot_count:-0}/3 current Agent snapshots contain the complete operational-store projection."
        log_error "Assign the operational-store property catalog to the three Agent product versions and regenerate their instance snapshots before deployment."
        return 1
    fi

    log_info "Validated the operational-store property catalog and 3 current Agent snapshots"
}

start_event_bootstrap_services() {
    log_info "Starting Postgres and event processors for event bootstrap..."

    ensure_release_assets || exit 1

    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }

    if "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" up -d postgres; then
        log_success "Postgres started"
    else
        log_error "Failed to start Postgres"
        return 1
    fi

    wait_for_postgres_ready || {
        log_error "Postgres did not become ready"
        return 1
    }

    if "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" up -d --no-deps hybrid-command hybrid-query; then
        log_success "Event processors started"
    else
        log_error "Failed to start event processors"
        return 1
    fi

    wait_for_container_running hybrid-command || {
        log_error "hybrid-command did not start"
        return 1
    }
    wait_for_container_running hybrid-query || {
        log_error "hybrid-query did not start"
        return 1
    }
}

get_event_store_count() {
    "$CONTAINER_RUNTIME_CMD" exec -e PGPASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" postgres \
        psql -h localhost -U postgres -d configserver -tAc "select count(*) from event_store_t;"
}

wait_for_container_running() {
    local container_name="$1"
    local max_attempts="${BOOTSTRAP_SERVICE_READY_ATTEMPTS:-30}"
    local interval="${BOOTSTRAP_SERVICE_READY_INTERVAL:-2}"
    local attempt=1
    local status=""

    while [ "$attempt" -le "$max_attempts" ]; do
        status="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || true)"
        if [[ "$status" == "running" ]]; then
            return 0
        fi

        sleep "$interval"
        attempt=$((attempt + 1))
    done

    return 1
}

wait_for_postgres_ready() {
    local max_attempts="${POSTGRES_READY_ATTEMPTS:-60}"
    local interval="${POSTGRES_READY_INTERVAL:-2}"
    local attempt=1
    local status=""

    while [ "$attempt" -le "$max_attempts" ]; do
        status="$("$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}}' postgres 2>/dev/null || true)"
        # Health checks are optional on some runtimes/images; pg_isready is the primary readiness signal.
        if [[ "$status" == running\ healthy* || "$status" == running* ]] &&
           "$CONTAINER_RUNTIME_CMD" exec postgres pg_isready -h localhost -U postgres -d configserver >/dev/null 2>&1; then
            return 0
        fi

        if [ $((attempt % 10)) -eq 0 ]; then
            log_info "Waiting for Postgres readiness (attempt $attempt/$max_attempts, status: ${status:-unknown})"
        fi

        sleep "$interval"
        attempt=$((attempt + 1))
    done

    return 1
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

wait_for_baseline_projection_cursor() {
    local max_attempts="${EVENT_PROJECTION_CURSOR_ATTEMPTS:-300}"
    local interval="${EVENT_PROJECTION_CURSOR_INTERVAL:-1}"
    local attempt=1
    local state=""
    local cursor=""
    local target=""

    while [ "$attempt" -le "$max_attempts" ]; do
        state="$("$CONTAINER_RUNTIME_CMD" exec -e PGPASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" postgres \
            psql -h localhost -U postgres -d configserver -tAc "
                SELECT COALESCE((
                  SELECT next_offset
                  FROM consumer_offsets
                  WHERE group_id = 'user-query-group'
                    AND topic_id = 1
                    AND partition_id = 0
                ), 0) || '|' || (SELECT next_offset FROM log_counter WHERE id = 1);
            " 2>/dev/null | tr -d '[:space:]' || true)"
        if [[ "$state" =~ ^([0-9]+)\|([0-9]+)$ ]]; then
            cursor="${BASH_REMATCH[1]}"
            target="${BASH_REMATCH[2]}"
            if [ "$cursor" -ge "$target" ]; then
                return 0
            fi
        else
            cursor="unavailable"
            target="unavailable"
        fi

        if (( attempt == 1 || attempt % 10 == 0 )); then
            log_info "Projection cursor is not ready: cursor=$cursor target=$target attempt=$attempt/$max_attempts"
        fi

        sleep "$interval"
        attempt=$((attempt + 1))
    done

    log_error "Event projection cursor did not catch up after $max_attempts attempts: cursor=$cursor target=$target"
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
    local mount_mode="ro,z"
    local disable_msys_pathconv=false
    local mount_source_dir
    local docker_mount_source_dir
    local container_events_dir="/events"
    local container_event_file
    local container_stdin_file="/dev/stdin"

    event_dir="$(cd "$(dirname "$event_file")" && pwd)"
    event_name="$(basename "$event_file")"
    import_network="${EVENT_IMPORT_NETWORK:-$(default_event_import_network)}"
    db_jdbc_url="${EVENT_IMPORT_DB_JDBC_URL:-jdbc:postgresql://postgres:5432/configserver}"
    # Always bind-mount the resolved event directory. A relative
    # RELEASE_ASSET_CACHE_DIR would otherwise be interpreted as a named volume
    # by Docker instead of the host directory checked below.
    mount_source_dir="$event_dir"
    docker_mount_source_dir="$mount_source_dir"

    # Git Bash/MSYS can rewrite /path arguments into host Windows paths.
    # Disable conversion for container commands so /events paths remain in-container paths.
    if [[ -n "${MSYSTEM:-}" ]]; then
        disable_msys_pathconv=true

        # On Git Bash + Docker Desktop, keep in-container paths literal but
        # convert host bind source to Windows format (e.g. C:/path).
        if ! container_runtime_is_podman; then
            if command -v cygpath >/dev/null 2>&1; then
                docker_mount_source_dir="$(cygpath -m "$mount_source_dir")"
            elif [[ "$mount_source_dir" =~ ^/([a-zA-Z])/(.*)$ ]]; then
                docker_mount_source_dir="${BASH_REMATCH[1]}:/${BASH_REMATCH[2]}"
            fi
        fi
    fi
    container_event_file="$container_events_dir/$event_name"

    if [[ ! -f "$mount_source_dir/$event_name" ]]; then
        log_error "Event import file not found at mount source: $mount_source_dir/$event_name"
        return 1
    fi

    # Docker Desktop does not support SELinux relabel options. Keep :z for
    # Linux Docker so the importer can read the cache on enforcing hosts.
    if [[ "$disable_msys_pathconv" == "true" ]]; then
        mount_mode="ro"
    fi

    if container_runtime_is_podman; then
        log_info "Streaming $event_file to event-importer over stdin"
            if [[ "$disable_msys_pathconv" == "true" ]]; then
                MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' "$CONTAINER_RUNTIME_CMD" run --rm -i \
                    --network "$import_network" \
                    -e DB_JDBC_URL="$db_jdbc_url" \
                    -e DB_USERNAME="${EVENT_IMPORT_DB_USERNAME:-postgres}" \
                    -e DB_PASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" \
                    -e DB_MAXIMUM_POOL_SIZE="${EVENT_IMPORT_DB_MAXIMUM_POOL_SIZE:-3}" \
                    "$importer_image" \
                    --filename "$container_stdin_file" \
                    "$@" < "$event_file"
            else
                "$CONTAINER_RUNTIME_CMD" run --rm -i \
                    --network "$import_network" \
                    -e DB_JDBC_URL="$db_jdbc_url" \
                    -e DB_USERNAME="${EVENT_IMPORT_DB_USERNAME:-postgres}" \
                    -e DB_PASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" \
                    -e DB_MAXIMUM_POOL_SIZE="${EVENT_IMPORT_DB_MAXIMUM_POOL_SIZE:-3}" \
                    "$importer_image" \
                    --filename "$container_stdin_file" \
                    "$@" < "$event_file"
            fi
        return $?
    fi
    event_mount="$docker_mount_source_dir:$container_events_dir:$mount_mode"
    log_info "Event importer mount: $docker_mount_source_dir -> $container_events_dir"

    log_info "Running $CONTAINER_RUNTIME_CMD event-importer image $importer_image on network $import_network"
    if [[ "$disable_msys_pathconv" == "true" ]]; then
        MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*' "$CONTAINER_RUNTIME_CMD" run --rm \
            --network "$import_network" \
            -v "$event_mount" \
            -e DB_JDBC_URL="$db_jdbc_url" \
            -e DB_USERNAME="${EVENT_IMPORT_DB_USERNAME:-postgres}" \
            -e DB_PASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" \
            -e DB_MAXIMUM_POOL_SIZE="${EVENT_IMPORT_DB_MAXIMUM_POOL_SIZE:-3}" \
            "$importer_image" \
            --filename "$container_event_file" \
            "$@"
    else
        "$CONTAINER_RUNTIME_CMD" run --rm \
            --network "$import_network" \
            -v "$event_mount" \
            -e DB_JDBC_URL="$db_jdbc_url" \
            -e DB_USERNAME="${EVENT_IMPORT_DB_USERNAME:-postgres}" \
            -e DB_PASSWORD="${EVENT_IMPORT_DB_PASSWORD:-secret}" \
            -e DB_MAXIMUM_POOL_SIZE="${EVENT_IMPORT_DB_MAXIMUM_POOL_SIZE:-3}" \
            "$importer_image" \
            --filename "$container_event_file" \
            "$@"
    fi
}

run_local_event_importer() {
    local event_file="$1"
    local database_url="$2"
    shift 2
    local importer_cmd=()
    local importer_work_dir="$REPO_DIR"

    if [[ -n "${EVENT_IMPORTER_CMD:-}" ]]; then
        read -r -a importer_cmd <<< "$EVENT_IMPORTER_CMD"
    else
        log_error "EVENT_IMPORT_RUNNER=local requires EVENT_IMPORTER_CMD to point to an executable importer command"
        return 1
    fi

    log_info "Running local event importer: ${importer_cmd[*]}"
    (
        cd "$importer_work_dir" || exit 1
        export DATABASE_URL="$database_url"
        "${importer_cmd[@]}" --filename "$event_file" "$@"
    )
}

import_events() {
    local import_mode="${IMPORT_EVENTS:-false}"
    local import_mode_lower="${import_mode,,}"
    local event_file="$RELEASE_ASSET_CACHE_DIR/events.json"
    local database_url="${EVENT_IMPORT_DATABASE_URL:-postgres://postgres:secret@localhost:5432/configserver}"
    local import_runner="${EVENT_IMPORT_RUNNER:-container}"
    local import_runner_lower
    local importer_image
    local extra_args=()
    local event_count=""

    case "$import_mode_lower" in
        false|no|0|"")
            log_info "Event import skipped. Set IMPORT_EVENTS=auto or IMPORT_EVENTS=true to import downloaded R2 events."
            return 0
            ;;
        auto|true|yes|1|force)
            ;;
        *)
            log_error "Invalid IMPORT_EVENTS value: $import_mode. Use false, auto, true, or force."
            return 1
            ;;
    esac

    if [[ -n "${EVENT_IMPORT_FILE:-}" ]]; then
        log_error "EVENT_IMPORT_FILE is not supported. Replace $event_file before starting deploy-local.sh if you need custom events."
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

    ensure_event_file || return 1

    if [ ! -f "$event_file" ]; then
        log_error "Event import file not found: $event_file"
        return 1
    fi

    if [[ -n "${EVENT_IMPORT_ARGS:-}" ]]; then
        read -r -a extra_args <<< "$EVENT_IMPORT_ARGS"
    fi

    if [[ "$event_count" -eq 0 ]]; then
        case " ${extra_args[*]} " in
            *" --historical-import "*)
                log_warning "Using explicitly requested historical import for the empty destination"
                ;;
            *" --bootstrap-import "*)
                ;;
            *)
                extra_args+=(
                    --bootstrap-import
                    --physical-chunk-events "${EVENT_IMPORT_PHYSICAL_CHUNK_EVENTS:-500}"
                    --physical-chunk-bytes "${EVENT_IMPORT_PHYSICAL_CHUNK_BYTES:-16777216}"
                    --max-event-bytes "${EVENT_IMPORT_MAX_EVENT_BYTES:-67108864}"
                )
                [[ "${EVENT_IMPORT_SYNCHRONOUS_COMMIT_OFF:-false}" =~ ^(1|true|TRUE|yes|YES)$ ]] &&
                    extra_args+=(--bootstrap-synchronous-commit-off)
                [[ "${EVENT_IMPORT_DIAGNOSE_FAILED_CHUNK:-false}" =~ ^(1|true|TRUE|yes|YES)$ ]] &&
                    extra_args+=(--diagnose-failed-chunk)
                [[ "${EVENT_IMPORT_PHYSICAL_CHUNKING_DISABLED:-false}" =~ ^(1|true|TRUE|yes|YES)$ ]] &&
                    extra_args+=(--physical-chunking-disabled)
                log_info "Empty destination detected; enabling direct event-table bootstrap import"
                ;;
        esac
    fi

    import_runner_lower="${import_runner,,}"
    load_env_file_var EVENT_IMPORTER_IMAGE
    importer_image="${EVENT_IMPORTER_IMAGE:-networknt/event-importer:latest}"

    log_info "Importing events from $event_file"
    case "$import_runner_lower" in
        container|docker|podman)
            if ! run_container_event_importer "$event_file" "$importer_image" "${extra_args[@]}"; then
                log_error "Container event import failed"
                return 1
            fi
            ;;
        local|host)
            if ! run_local_event_importer "$event_file" "$database_url" "${extra_args[@]}"; then
                log_error "Local event import failed"
                return 1
            fi
            ;;
        auto)
            if ! run_container_event_importer "$event_file" "$importer_image" "${extra_args[@]}"; then
                log_warning "Container event import failed; trying local importer fallback"
                if ! run_local_event_importer "$event_file" "$database_url" "${extra_args[@]}"; then
                    log_error "Local event import fallback failed"
                    return 1
                fi
            fi
            ;;
        *)
            log_error "Invalid EVENT_IMPORT_RUNNER value: $import_runner. Use container, local, or auto."
            return 1
            ;;
    esac
    log_success "Event import completed"
}

event_import_enabled() {
    local import_mode="${IMPORT_EVENTS:-false}"
    local import_mode_lower="${import_mode,,}"

    case "$import_mode_lower" in
        false|no|0|"") return 1 ;;
        *) return 0 ;;
    esac
}

bootstrap_events_if_requested() {
    if ! event_import_enabled; then
        import_events
        return 0
    fi

    start_event_bootstrap_services || return 1
    import_events || return 1
    log_info "Waiting for asynchronous baseline projection cursor before full-stack startup"
    wait_for_baseline_projection_cursor
}

apply_requested_db_patches() {
    local patch_args=()
    local target_schema="public"

    if [[ -z "${PORTAL_DB_PATCHES:-}" ]]; then
        return 0
    fi
    if is_true "${CLEAN_VOLUMES:-false}"; then
        log_info "Skipping PORTAL_DB_PATCHES because CLEAN_VOLUMES recreates the database from current init.sql."
        return 0
    fi

    # Consume the complete value so a readable multiline patch list behaves
    # the same as a single whitespace-separated line.
    IFS=$' \t\n' read -r -d '' -a patch_args < <(printf '%s\0' "$PORTAL_DB_PATCHES")
    if ((${#patch_args[@]} == 0)); then
        log_error "PORTAL_DB_PATCHES did not contain any patch paths"
        return 1
    fi

    if [[ "$DOCKER_COMPOSE_DIR" == "$BASE_DIR/portal-config-loc/all-in-lt" ]]; then
        target_schema="configserver"
    fi

    log_info "Starting Postgres to apply ${#patch_args[@]} requested database patch(es)..."
    (
        cd "$DOCKER_COMPOSE_DIR" || exit 1
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" up -d postgres
    ) || return 1
    wait_for_postgres_ready || {
        log_error "Postgres did not become ready for database patching"
        return 1
    }

    log_info "Applying requested database patches to schema $target_schema"
    CONTAINER_CMD="$CONTAINER_RUNTIME_CMD" \
        "$SCRIPT_DIR/apply-db-patches.sh" "$target_schema" "${patch_args[@]}" || {
        log_error "Failed to apply requested database patches"
        return 1
    }
    log_success "Requested database patches applied"
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
        log_info "Compose status:"
        "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps
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

    # Step 3: Upgrade a preserved database before any application service starts.
    apply_requested_db_patches || exit 1

    # Step 4: Import events before starting services that require OAuth keys.
    if [[ -z "${IMPORT_EVENTS+x}" ]]; then
        log_info "IMPORT_EVENTS not set; defaulting to auto for full deployment."
        IMPORT_EVENTS=auto
    fi
    bootstrap_events_if_requested || exit 1

    # Step 5: Start Compose
    if ! start_docker_compose; then
        log_error "Failed to start Compose"
        exit 1
    fi

    # Step 6: Show summary
    show_summary

    log_success "Deployment completed successfully!"
    log_info "To view logs: ${DOCKER_COMPOSE_CMD[*]} ${DOCKER_COMPOSE_FILES[*]} logs -f"
}

# Handle script arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        ;;
    *)
        configure_release_image_env
        configure_light_portal_env
        configure_local_reasoning_seal_key
        configure_local_runtime_identity
        prepare_operational_database_secret "${1:-}"
        ;;
esac

case "${1:-}" in
    "stop")
        stop_docker_compose
        ;;
    "start")
        bootstrap_events_if_requested
        start_docker_compose
        ;;
    "restart")
        stop_docker_compose
        sleep 2
        bootstrap_events_if_requested
        start_docker_compose
        ;;
    "status")
        cd "$DOCKER_COMPOSE_DIR" && "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" ps
        ;;
    "logs")
        cd "$DOCKER_COMPOSE_DIR" && "${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" logs -f --tail=100
        ;;
    "provisioner-start")
        start_operational_store_provisioner
        ;;
    "provisioner-stop")
        stop_operational_store_provisioner
        ;;
    "provisioner-status")
        cd "$DOCKER_COMPOSE_DIR" || exit 1
        provisioner_id="$("${DOCKER_COMPOSE_CMD[@]}" "${DOCKER_COMPOSE_FILES[@]}" --profile operational-store-provisioning ps -q operational-store-provisioner)"
        if [[ -n "$provisioner_id" ]] &&
           [[ "$("$CONTAINER_RUNTIME_CMD" inspect -f '{{.State.Status}}' "$provisioner_id" 2>/dev/null)" == "running" ]]; then
            echo "operational-store provisioner Compose service is running"
        else
            echo "operational-store provisioner Compose service is not running"
            exit 1
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [config] [service-type] [command]"
        echo ""
        echo "Config (optional):"
        echo "  kafka           Use Kafka configuration (default)"
        echo "  pg              Use Postgres configuration"
        echo "  lt              Use Light Postgres configuration (one hybrid-query)"
        echo ""
        echo "Service type (optional):"
        echo "  java            Use Java service overrides (pg only; default for pg)"
        echo "  rust            Use Rust services (pg override; accepted for lt compatibility)"
        echo ""
        echo "Commands:"
        echo "  (no command)    Full deployment (stop, start, optional event import)"
        echo "  stop            Stop Compose services"
        echo "  start           Start Compose services"
        echo "  restart         Restart Compose services"
        echo "  status          Show Compose status"
        echo "  logs            Follow Compose logs"
        echo "  provisioner-start   Start only the operational-store provisioner Compose service"
        echo "  provisioner-stop    Stop only the operational-store provisioner Compose service"
        echo "  provisioner-status  Show operational-store provisioner Compose service status"
        echo "  help            Show this help message"
        echo ""
        echo "Environment:"
        echo "  COMPOSE_CMD=\"podman compose\"     Use Podman Compose instead of the default docker compose"
        echo "  CONTAINER_CMD=podman              Container command for exec/inspect checks"
        echo "  LIGHT_GATEWAY_HOST_PORT=443       Gateway host port (default 443)"
        echo "  LLM_GATEWAY_HOST_PORT=8444        Dedicated LLM gateway host port (default 8444)"
        echo "  LLM_GATEWAY_LIGHT_PORTAL_AUTHORIZATION='Bearer ...'  LLM gateway service token"
        echo "  KNOWLEDGE_SNAPSHOT_AUTHORIZATION='...'  Token used by light-knowledge-admin snapshot refresh"
        echo "  LIGHT_PORTAL_ASSET_BASE_URL=...   CDN base URL for released asset zip files"
        echo "  RELEASE_ASSET_CACHE_DIR=...       Cache directory for downloaded asset zip files"
        echo "  REFRESH_RELEASE_ASSETS=true       Refresh cached assets and replace service JARs"
        echo "  IMPORT_EVENTS=auto                Import downloaded events.json only when event_store_t is empty (default for full deployment)"
        echo "  IMPORT_EVENTS=false               Skip event import"
        echo "  IMPORT_EVENTS=true                Import downloaded events.json even when rows already exist"
        echo "  PORTAL_DB_PATCHES='path ...'      Apply these ordered SQL patches to a preserved local database"
        echo "  OPERATIONAL_PROPERTY_CATALOG_FILE=...  Operational-store property catalog event file used in preflight guidance"
        echo "  OPERATIONAL_PROVISIONER_TOKEN_FILE=...  Mode-600 service token for the operational-store worker"
        echo "  OPERATIONAL_PROVISIONER_LEASE_SECONDS=600  Local provider lease duration for initial database bootstrap"
        echo "  RUNTIME_QUALIFICATION_TIMEOUT_SECONDS=120  Maximum wait for required all-in-lt services"
        echo "  RUNTIME_QUALIFICATION_INTERVAL_SECONDS=2   Seconds between required-service checks"
        echo "  EVENT_IMPORT_RUNNER=container     Use container, local, or auto importer runner"
        echo "  EVENT_IMPORTER_IMAGE=...          Container image for event import"
        echo "  EVENT_IMPORT_NETWORK=...          Override Compose network for event importer"
        echo "  EVENT_IMPORTER_CMD=...            Override local importer command when EVENT_IMPORT_RUNNER=local"
        echo "  EVENT_IMPORT_PHYSICAL_CHUNK_EVENTS=500  Events per physical bootstrap commit (default and maximum: 500)"
        echo "  EVENT_PROJECTION_CURSOR_ATTEMPTS=300     Maximum projection cursor readiness attempts"
        echo "  EVENT_PROJECTION_CURSOR_INTERVAL=1      Seconds between projection cursor checks"
        echo "  EVENT_IMPORT_ARGS='--historical-import --legacy-write-fenced'  Recover a preserved pre-graph-metadata snapshot instead of automatic bootstrap"
        echo "  RELEASE_IMAGE_ENV_FILE=...        Compose image env file path"
        echo "  RELEASE_IMAGE_ENV_URL=...         Download docker-images.env with curl when local file is missing"
        echo "  RELEASE_IMAGE_ENV_S3_URI=...      Download docker-images.env with aws s3 cp when local file is missing"
        echo "  RELEASE_IMAGE_ENV_CACHE=...       Default cache path for downloaded docker-images.env"
        echo "  LIGHT_PORTAL_ENV_FILE=...         Local secret env file (default: ~/.config/lightapi/light-portal.env)"
        ;;
    *)
        main
        ;;
esac
