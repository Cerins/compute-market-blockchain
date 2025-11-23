#!/bin/bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <code_file>" >&2
  exit 1
fi

CODE_FILE="$1"

if [ ! -f "$CODE_FILE" ]; then
  echo "Error: Code file not found: $CODE_FILE" >&2
  exit 1
fi

CODE_FILE_ABS="$(readlink -f "$CODE_FILE")"
CODE_BASENAME="$(basename "$CODE_FILE_ABS")"

IMAGE="${IMAGE:-python:3.12-slim}"

# TODO check if you can do better seccomp or apparmor
docker run --rm -i \
  --name "py-sandbox-$$" \
  --network=none \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,nodev,size=64m \
  --tmpfs /run:rw,noexec,nosuid,nodev,size=16m \
  --cap-drop=ALL \
  --security-opt no-new-privileges:true \
  --security-opt apparmor=docker-default \
  --security-opt seccomp=unconfined \
  --user 65534:65534 \
  --workdir /work \
  -v "${CODE_FILE_ABS}:/work/${CODE_BASENAME}:ro" \
  "$IMAGE" \
  python3 "/work/${CODE_BASENAME}"
