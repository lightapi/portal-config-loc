#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_QUERY_DIR="${BASE_DIR}/all-in-pg/hybrid-query/service"
TARGET_COMMAND_DIR="${BASE_DIR}/all-in-pg/hybrid-command/service"
GROUP_ID="${GROUP_ID:-net.lightapi}"
VERSION="${VERSION:-2.3.4-SNAPSHOT}"

if [ "${DEBUG:-false}" = "true" ]; then
  set -x
fi

projects=(
  "attribute"
  "blog"
  "category"
  "client"
  "config"
  "deployment"
  "document"
  "error"
  "form"
  "group"
  "host"
  "instance"
  "maproot"
  "news"
  "oauth"
  "page"
  "position"
  "product"
  "ref"
  "role"
  "rule"
  "schedule"
  "schema"
  "service"
  "tag"
  "template"
  "user"
)

REMOTE_REPOS="central::default::https://repo1.maven.org/maven2"
if [[ "${VERSION}" == *-SNAPSHOT ]]; then
  REMOTE_REPOS="${REMOTE_REPOS},snapshot::default::https://central.sonatype.com/repository/maven-snapshots/"
fi

mkdir -p "${TARGET_QUERY_DIR}" "${TARGET_COMMAND_DIR}"

find "${TARGET_QUERY_DIR}" -maxdepth 1 -type f ! -name '.gitkeep' -delete
find "${TARGET_COMMAND_DIR}" -maxdepth 1 -type f ! -name '.gitkeep' -delete

download_artifact() {
  local artifact_id="$1"
  local output_dir="$2"

  echo "Downloading ${GROUP_ID}:${artifact_id}:${VERSION}"
  mvn -q -U dependency:copy \
    -Dartifact="${GROUP_ID}:${artifact_id}:${VERSION}:jar" \
    -DoutputDirectory="${output_dir}" \
    -DremoteRepositories="${REMOTE_REPOS}" \
    -Dtransitive=false
}

for project in "${projects[@]}"; do
  download_artifact "${project}-query" "${TARGET_QUERY_DIR}"
  download_artifact "${project}-command" "${TARGET_COMMAND_DIR}"
done

echo
echo "Downloaded query jars to ${TARGET_QUERY_DIR}"
echo "Downloaded command jars to ${TARGET_COMMAND_DIR}"
