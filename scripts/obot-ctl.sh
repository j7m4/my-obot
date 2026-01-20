#!/usr/bin/env sh

DEPLOYMENT="momas"
CONTAINER_NAME="obot-$DEPLOYMENT"
IMAGE="ghcr.io/obot-platform/obot:latest"
PORT="28282:8080"
VOLUME="obot-$DEPLOYMENT:/data"

# ENVIRONMENT one of:
# -e OPENAI_API_KEY=$OPENAI_API_KEY \
# -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \

show_usage() {
  echo "Usage: $0 {start|stop|restart|status|logs|pull|clean}"
  echo ""
  echo "Commands:"
  echo "  start    - Start the obot container"
  echo "  stop     - Stop the obot container"
  echo "  restart  - Restart the obot container"
  echo "  status   - Show container status"
  echo "  logs     - Show container logs (use -f to follow)"
  echo "  pull     - Pull latest image"
  echo "  clean    - Stop container, remove it, and delete the volume"
  exit 1
}

start_container() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
      echo "Container $CONTAINER_NAME is already running"
      return 0
    else
      echo "Starting existing container: $CONTAINER_NAME"
      docker start $CONTAINER_NAME
      return $?
    fi
  fi

  echo "Starting new obot deployment: $DEPLOYMENT"
  docker run -d \
    --name $CONTAINER_NAME \
    -p $PORT \
    -v $VOLUME \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
    $IMAGE

  if [ $? -eq 0 ]; then
    echo "Container started successfully"
    echo "Access obot at: http://localhost:28282"
  else
    echo "Failed to start container"
    return 1
  fi
}

stop_container() {
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
  else
    echo "Container $CONTAINER_NAME is not running"
  fi
}

restart_container() {
  echo "Restarting container: $CONTAINER_NAME"
  stop_container
  sleep 2
  start_container
}

show_status() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container details:"
    docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  else
    echo "Container $CONTAINER_NAME does not exist"
  fi
}

show_logs() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    shift
    docker logs $@ $CONTAINER_NAME
  else
    echo "Container $CONTAINER_NAME does not exist"
  fi
}

pull_image() {
  echo "Pulling latest image: $IMAGE"
  docker pull $IMAGE
}

clean_deployment() {
  VOLUME_NAME="obot-$DEPLOYMENT"

  # Stop container if running
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
  fi

  # Remove container if it exists
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing container: $CONTAINER_NAME"
    docker rm $CONTAINER_NAME
  fi

  # Remove volume if it exists
  if docker volume ls --format '{{.Name}}' | grep -q "^${VOLUME_NAME}$"; then
    echo "Removing volume: $VOLUME_NAME"
    docker volume rm $VOLUME_NAME
    echo "Clean complete - all data has been removed"
  else
    echo "Volume $VOLUME_NAME does not exist"
  fi
}

# Main script logic
if [ $# -eq 0 ]; then
  show_usage
fi

case "$1" in
  start)
    start_container
    ;;
  stop)
    stop_container
    ;;
  restart)
    restart_container
    ;;
  status)
    show_status
    ;;
  logs)
    show_logs "$@"
    ;;
  pull)
    pull_image
    ;;
  clean)
    clean_deployment
    ;;
  *)
    echo "Unknown command: $1"
    show_usage
    ;;
esac
