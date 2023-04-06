#!/bin/bash -e
# Provide a set of common docker helper functions.

# To be used on Windows Subsystem for Linux to connect to Host Docker engine
export DOCKER_HOST="tcp://127.0.0.1:2375"

#######################################################################
# Return status of Docker Engine daemon
# Arguments:
#   None
# Returns:
#   0 - if up and running, else not running
#######################################################################
function docker_up() {
  docker info 2>1 >/dev/null
  echo $?
}

#######################################################################
# Detects whether a process is running inside Docker container
# Arguments:
#   None
# Returns:
#   String
#######################################################################
docker_container_active() {
    docker_status=$(cat /proc/self/cgroup | grep -c docker)
    if [[ "$docker_status" -eq "0" ]]; then
        echo "Outside Docker container"
    else
        echo "Inside Docker container"
    fi
}

#######################################################################
# Show docker image labels as key=value pairs
# Arguments:
#   image_url:image_tag
# Returns:
#   None
#######################################################################
function docker_labels() {
    if [[ -z "$1" ]]; then
        echo "Missing docker image name"
        return
    fi
    docker inspect --format '{{ range $k,$v:=.Config.Labels }}{{ $k }}={{ println $v}}{{end}}' $1
}

function docker_container_latest() {
  docker ps --last 1 -q
}

#######################################################################
# Retrieve IP address of the running container
# Arguments:
#   id - container name or id
# Returns:
#   IP address of the running container or None
#######################################################################
function docker_container_ip() {
  container_id=$1

  [[ -z "$container_id" ]] && container_id=$(docker_container_latest)

  if [[ ! -z "$container_id" ]]
  then
      name=$(docker inspect --format '{{ .Name }}' $container_id | tr -d '/')
      ip_address=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $container_id)
      echo "Container $name has IP: $ip_address"
  else
      echo "There are no running containers!"
  fi
}

#######################################################################
# Remove all dangling resources (not associated with a container):
# images, containers, volumes and networks
#######################################################################
function docker_prune() {
    docker system prune --force 2>/dev/null
}

# Run nmap from Ubuntu custom image on WSL
function nmap() {
  if [[ $(docker_up) -eq "0" ]]; then
    docker run --rm ubuntu:custom nmap "$@"
  fi
}
