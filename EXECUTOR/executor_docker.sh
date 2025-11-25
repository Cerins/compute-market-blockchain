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

IMAGE="${IMAGE:-executor-cpu}"

# Debug stuff
# echo "IMAGE: $IMAGE"

# TODO check if you can do better seccomp or apparmor
# Entrypoint is empty so that nvidia container will not spam stdout with container notice
docker run --rm --gpus all -i \
  --entrypoint "" \
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
