#!/bin/sh
# Build mod_kazoo against an upstream FreeSWITCH release in Docker and check
# that the module loads without an executable stack.
#
#   ./check-build.sh
#   FS_VERSION=v1.11.2 ERLANG_VERSION=28 ./check-build.sh
set -eu

cd "$(dirname "$0")"

docker build \
    --build-arg "FS_VERSION=${FS_VERSION:-v1.11.3}" \
    --build-arg "ERLANG_VERSION=${ERLANG_VERSION:-29}" \
    -f docker/Dockerfile.check \
    -t mod_kazoo-check .
