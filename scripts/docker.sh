#!/usr/bin/env bash
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_dir}/libs/utils.sh"

##########################################################
# Builds the docker image at the provided path with the provided
# image tag.
# Globals:
#   None
# Arguments:
#   _path         - The path to the Dockerfile.
#   _img_name     - The name to tag the image with.
#   _docker_file  - The docker file to build. (Default: "Dockerfile")
# Env Vars:
#   IMG_VERSION_TAG - The version tag to use for the image. (Default: "latest")
##########################################################
function docker_build() {
  local _path=${1}
  local _img_name=${2}
  local _docker_file=${3:-"Dockerfile"}
  local _img_tag=${IMG_VERSION_TAG:-"latest"}

  _debug "Running 'docker build ${_path} --file ${_docker_file} --tag ${_img_name}:${_img_tag}"
  docker build "${_path}" --file "${_docker_file}" --tag "${_img_name}:${_img_tag}"
}

##########################################################
# Pushes the built image with the provided name.
# Globals:
#   None
# Arguments:
#   _img_name - The name of the image to push.
# Env Vars:
#   IMG_VERSION_TAG - The version tag to use for the image. (Default: "latest")
##########################################################
function docker_push() {
  local _img_name=${1}
  local _img_tag=${IMG_VERSION_TAG:-"latest"}

  _debug "Running 'docker push ${_img_name}:${_img_tag}'"
  docker push "${_img_name}:${_img_tag}"
}

case ${1} in
  "build") shift && docker_build "${@}" ;;
  "push") shift && docker_push "${@}" ;;
  *) _error "Bad inputs" ;;
esac
