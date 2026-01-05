#!/bin/bash
# deploy.sh - Full deployment script with Docker Compose management

set -e  # Exit on error

# Configuration
BASE_DIR=~/lightapi
DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-one"

# Check for config argument
if [[ "$1" == "kafka" ]]; then
    DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-one"
    shift
elif [[ "$1" == "pg" ]]; then
    DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-pg"
    shift
elif [[ "$1" == "light" ]]; then
    DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-light"
    shift
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if docker-compose exists
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose not found. Please install docker-compose."
        exit 1
    fi
    
    # Check if mvn exists
    if ! command -v mvn &> /dev/null; then
        log_error "Maven (mvn) not found. Please install Maven."
        exit 1
    fi
    
    # Check if build script exists
    if [ ! -f "$BUILD_SCRIPT" ]; then
        log_error "Build script not found at $BUILD_SCRIPT"
        exit 1
    fi
    
    # Check if docker-compose.yml exists
    if [ ! -f "$DOCKER_COMPOSE_DIR/docker-compose.yml" ]; then
        log_error "docker-compose.yml not found at $DOCKER_COMPOSE_DIR"
        exit 1
    fi
    
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
    if docker-compose ps --services --filter "status=running" 2>/dev/null | grep -q .; then
        log_info "Stopping running containers..."
        docker-compose down --timeout 30
        
        # Wait for containers to stop
        local max_wait=60
        local wait_time=0
        
        while docker-compose ps --services --filter "status=running" 2>/dev/null | grep -q .; do
            if [ $wait_time -ge $max_wait ]; then
                log_warning "Some containers are still running after $max_wait seconds"
                log_info "Force stopping containers..."
                docker-compose down --timeout 10
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

# Build and copy JAR files
build_and_copy() {
    log_info "Starting build process..."
    
    cd "$BASE_DIR" || {
        log_error "Cannot cd to $BASE_DIR"
        exit 1
    }
    
    # Make build script executable
    chmod +x "$BUILD_SCRIPT"
    
    # Run build script
    if "$BUILD_SCRIPT"; then
        log_success "Build process completed"
        return 0
    else
        log_error "Build process failed"
        return 1
    fi
}

# Start Docker Compose
start_docker_compose() {
    log_info "Starting Docker Compose services..."
    
    cd "$DOCKER_COMPOSE_DIR" || {
        log_error "Cannot cd to $DOCKER_COMPOSE_DIR"
        exit 1
    }
    
    # Start services in detached mode
    log_info "Starting services..."
    if docker-compose up -d; then
        log_success "Docker Compose services started"
        
        # Show status
        log_info "Current service status:"
        docker-compose ps
        
        # Tail logs for a few seconds to show startup
        log_info "Showing startup logs (tail for 10 seconds)..."
        timeout 10 docker-compose logs -f --tail=10 2>/dev/null || true
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
        local total_services=$(docker-compose ps --services | wc -l)
        local healthy_services=$(docker-compose ps --services | while read service; do
            if docker-compose ps --filter "status=running" "$service" | grep -q "Up"; then
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
    docker-compose ps
    return 1
}

# Show deployment summary
show_summary() {
    log_info "=== Deployment Summary ==="
    log_info "Log file: $LOG_FILE"
    log_info "Docker Compose directory: $DOCKER_COMPOSE_DIR"
    
    cd "$DOCKER_COMPOSE_DIR" && {
        log_info "Running containers:"
        docker-compose ps --services | while read service; do
            status=$(docker-compose ps "$service" | tail -1 | awk '{print $3}')
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
    
    # Step 1: Check prerequisites
    check_prerequisites
    
    # Step 2: Stop Docker Compose
    stop_docker_compose
    
    # Step 3: Build and copy JAR files
    if ! build_and_copy; then
        log_error "Build failed. Attempting to restart Docker Compose..."
        start_docker_compose
        exit 1
    fi
    
    # Step 4: Start Docker Compose
    if ! start_docker_compose; then
        log_error "Failed to start Docker Compose"
        exit 1
    fi
    
    # Step 5: Verify services
    verify_services
    
    # Step 6: Show summary
    show_summary
    
    log_success "Deployment completed successfully!"
    log_info "To view logs: docker-compose -f $DOCKER_COMPOSE_DIR/docker-compose.yml logs -f"
    
    cd "$DOCKER_COMPOSE_DIR" || return 1
    docker-compose logs -f light-gateway oauth-kafka hybrid-query1 hybrid-query2 hybrid-query3 hybrid-command > output.log &
    ./log-monitor output.log

}

# Handle script arguments
case "${1:-}" in
    "stop")
        stop_docker_compose
        ;;
    "start")
        start_docker_compose
        ;;
    "build")
        build_and_copy
        ;;
    "restart")
        stop_docker_compose
        sleep 2
        start_docker_compose
        ;;
    "status")
        cd "$DOCKER_COMPOSE_DIR" && docker-compose ps
        ;;
    "logs")
        cd "$DOCKER_COMPOSE_DIR" && docker-compose logs -f --tail=100
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [config] [command]"
        echo ""
        echo "Config (optional):"
        echo "  kafka           Use Kafka configuration (default)"
        echo "  pg              Use Postgres configuration"
        echo "  light           Use Light configuration"
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
