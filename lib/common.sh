#!/bin/bash

steptxt="----->"
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'                              # No Color
CURL="curl -L --retry 15 --retry-delay 2" # retry for up to 30 seconds

info() {
  echo -e "${GREEN}       $*${NC}"
}

warn() {
  echo -e "${YELLOW} !!    $*${NC}"
}

err() {
  echo -e "${RED} !!    $*${NC}" >&2
}

step() {
  echo "$steptxt $*"
}

start() {
  echo -n "$steptxt $*... "
}

finished() {
  echo "done"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
  Darwin) sed -l "$c" ;; # mac/bsd sed: -l buffers on line boundaries
  *) sed -u "$c" ;;      # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

function resolve_nodejs_major_latest_release_from_packagejson() {
  local src_dir="${1}"
  local major_version=$(cat "${src_dir}/package.json" | jq '.devDependencies."@types/node"' | tr -d '"' | awk -F \. {'print $1'})
  echo "${major_version}"
}

function fetch_nodejs_release_from_latest() {
  local major_release="${1}"
  local releases_url="https://nodejs.org/download/release/index.json"
  local latest_release=$(curl "$releases_url" | jq --arg major_release "v${major_release}" '[.[] | select(.version | test($major_release)) | .version] | .[0]' | tr -d '"')
  echo "${latest_release}"
}

function install_nodejs() {
  local location="${1}"
  local src_dir="${2}"
  local distro="linux-x64"
  local major_latest_release
  local latest_release

  if [ -f "${src_dir}/package.json" ]; then
    echo "Resolving node major latest release from ${src_dir}/package.json"
    major_latest_release=$(resolve_nodejs_major_latest_release_from_packagejson ${src_dir})
  elif [ -f "$ENV_DIR/NODEJS_MAJOR_LATEST_VERSION" ]; then
    major_latest_release=$(cat "$ENV_DIR/NODEJS_MAJOR_LATEST_VERSION")
  else
    major_latest_release=$(fetch_github_latest_release "${TMP_PATH}" "nodejs/node" | tr -d 'v' | awk -F \. {'print $1'})
  fi
  echo "Downloading and installing latest release nodejs $major_latest_release"
  local latest_release=$(fetch_nodejs_release_from_latest "$major_latest_release")
  local dist_file="node-${latest_release}-${distro}.tar.xz"
  local dist_url="https://nodejs.org/dist/latest-v${major_latest_release}.x/${dist_file}"
  step "Fetch nodejs ${latest_release} dist"
  if [ -f "${CACHE_DIR}/dist/${dist_file}" ]; then
    info "Dist files are already downloaded"
  else
    info "Downloading from $dist_url"
    ${CURL} -g -o "${CACHE_DIR}/dist/${dist_file}" "${dist_url}"
  fi
  tar -xJf "$CACHE_DIR/dist/${dist_file}" --strip-components=1 -C "$location"
  finished
}

function install_yarn() {
  info "Installing latest Yarn release from tarball"
  local location="${1}"
  local dist_file="yarn-latest.tar.gz"
  local dist_url="https://yarnpkg.com/latest.tar.gz"
  if [ -f "${CACHE_DIR}/dist/${dist_file}" ]; then
    info "Dist files are already downloaded"
  else
    info "Downloading from $dist_url"
    ${CURL} -g -o "${CACHE_DIR}/dist/${dist_file}" "${dist_url}"
  fi
  tar zxf "$CACHE_DIR/dist/${dist_file}" --strip-components=1 -C "$location"
  finished
}

function fetch_grist_source() {
  local version="$1"
  local location="$2"
  local src_file="${version}.tar.gz"
  local src_url
  local download_url
  download_url="https://github.com/gristlabs/grist-core/archive/refs/tags/${src_file}"
  src_url=$(echo "${download_url}" | xargs)
  src_url="${src_url%\"}"
  src_url="${src_url#\"}"
  step "Fetch grist ${version} src"
  if [ -f "${CACHE_DIR}/src/grist-${src_file}" ]; then
    info "Source files are already downloaded"
  else
    info "Downloading from $src_url"
    ${CURL} -g -o "${CACHE_DIR}/src/grist-${src_file}" "${src_url}"
  fi
  tar xzf "$CACHE_DIR/src/grist-${src_file}" --strip-components=1 -C "$location"
  finished
}

function fetch_github_latest_release() {
  local location="$1"
  local repo="$2"
  local repo_checksum
  repo_checksum=$(printf "%s" "${repo}" | sha256sum | grep -o '^\S\+')
  local http_code
  if [[ -f "$ENV_DIR/GITHUB_ID" ]]; then
    GITHUB_ID=$(cat "$ENV_DIR/GITHUB_ID")
  fi
  if [[ -f "$ENV_DIR/GITHUB_SECRET" ]]; then
    GITHUB_SECRET=$(cat "$ENV_DIR/GITHUB_SECRET")
  fi
  local latest_release_url
  latest_release_url="https://api.github.com/repos/${repo}/releases/latest"
  http_code=$(curl -L --retry 15 --retry-delay 2 -G -o "${TMP_PATH}/latest_release_${repo_checksum}.json" -w '%{http_code}' -u "${GITHUB_ID}:${GITHUB_SECRET}" -H "Accept: application/vnd.github.v3+json" "${latest_release_url}")
  local latest_release_version
  latest_release_version=""
  if [[ $http_code == 200 ]]; then
    latest_release_version=$(jq <"${TMP_PATH}/latest_release_${repo_checksum}.json" '.tag_name' | xargs)
    latest_release_version="${latest_release_version%\"}"
    latest_release_version="${latest_release_version#\"}"
  fi
  echo "$latest_release_version"
}
