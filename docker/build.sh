#!/bin/bash -e
# Runs ../build.sh with its arguments in a container that has its tools, or a shell:
#   docker/build.sh android arm64
#   docker/build.sh shell

docker=$(cd "$(dirname "$0")" && pwd)
docker build -t aiostreams-libs-builder "$docker"
docker run --rm -it -v "$docker/..:/home/mpvbuilder/libs" \
	aiostreams-libs-builder "$@"
