#!/usr/bin/env bash

set -x

echo "Searching for Docker image ..."
DOCKER_IMAGE_ID=$(docker images --format="{{.ID}}" docker-pulseaudio-example:latest | head -n 1)
echo "Found and using ${DOCKER_IMAGE_ID}"

USER_UID=$(id -u)

# OSX local ip 
IP=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}' | head -n 1)

docker run -t -i \
  -e PULSE_SERVER=tcp:$IP:4713 \
  -e PULSE_COOKIE=/run/pulse/cookie \
  -v ~/.config/pulse/cookie:/run/pulse/cookie \
  ${DOCKER_IMAGE_ID} \
  ${@}
