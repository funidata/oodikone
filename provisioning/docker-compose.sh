#!/bin/sh

export BUILD_UID=$(id -u)
export BUILD_GID=$(id -g)
export BUILD_DATE=$(date +%Y%m%d)

exec docker compose "$@"
