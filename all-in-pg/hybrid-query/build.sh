#!/bin/bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-networknt/portal-hybrid-query}"
BASE_IMAGE="${BASE_IMAGE:-networknt/portal-hybrid-query:2.2.1}"
VERSION=""
LOCAL_BUILD=false
NO_CACHE_ARG=""

show_help() {
  echo " "
  echo "Error: $1"
  echo " "
  echo "    build.sh [VERSION] [-l|--local] [--no-cache]"
  echo " "
  echo "    where [VERSION] is the wrapper image tag to build and publish"
  echo "          [-l|--local] optionally builds the image locally without pushing"
  echo " "
  echo "    example: ./build.sh 2.2.1-services"
  echo "    example: ./build.sh 2.2.1-services -l"
  echo " "
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--local)
      LOCAL_BUILD=true
      shift
      ;;
    --no-cache)
      NO_CACHE_ARG="--no-cache"
      shift
      ;;
    -*)
      show_help "Invalid option: $1"
      exit 1
      ;;
    *)
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
      else
        show_help "Invalid option: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  show_help "[VERSION] parameter is missing"
  exit 1
fi

echo "Building ${IMAGE_NAME}:${VERSION} from ${BASE_IMAGE}"
docker build ${NO_CACHE_ARG} \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  -t "${IMAGE_NAME}:${VERSION}" \
  -f Dockerfile .

if $LOCAL_BUILD; then
  echo "Skipping DockerHub publish due to local build flag (-l or --local)"
else
  echo "Pushing ${IMAGE_NAME}:${VERSION}"
  docker push "${IMAGE_NAME}:${VERSION}"
fi
