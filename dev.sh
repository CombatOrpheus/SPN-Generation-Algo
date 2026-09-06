#!/usr/bin/env bash
set -euo pipefail

# Directory of this script (repository root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="spn-generation-algo-dev:latest"

# Detect container runtime: respect CONTAINER_TOOL if set, otherwise auto-detect
if [ -n "${CONTAINER_TOOL:-}" ]; then
    RUNTIME="$CONTAINER_TOOL"
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    RUNTIME="docker"
elif command -v podman >/dev/null 2>&1; then
    RUNTIME="podman"
elif command -v docker >/dev/null 2>&1; then
    RUNTIME="docker"
else
    echo "Error: Neither Docker nor Podman is installed or running." >&2
    exit 1
fi

USER_NAME="$(id -un 2>/dev/null || echo developer)"
USER_UID="$(id -u 2>/dev/null || echo 1000)"
USER_GID="$(id -g 2>/dev/null || echo 1000)"

build_image() {
    echo "[dev.sh] Building ${IMAGE_NAME} using ${RUNTIME}..."
    if [ "$RUNTIME" = "podman" ]; then
        podman build \
            --build-arg USER_NAME="$USER_NAME" \
            --build-arg USER_UID="$USER_UID" \
            --build-arg USER_GID="$USER_GID" \
            -t "$IMAGE_NAME" \
            -f "${SCRIPT_DIR}/Dockerfile" \
            "${SCRIPT_DIR}"
    else
        docker build \
            --build-arg USER_NAME="$USER_NAME" \
            --build-arg USER_UID="$USER_UID" \
            --build-arg USER_GID="$USER_GID" \
            -t "$IMAGE_NAME" \
            -f "${SCRIPT_DIR}/Dockerfile" \
            "${SCRIPT_DIR}"
    fi
}

ensure_image() {
    if ! "$RUNTIME" image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        if "$RUNTIME" image inspect "spn-algo-octave-dev:latest" >/dev/null 2>&1; then
            echo "[dev.sh] Reusing existing spn-algo-octave-dev:latest as ${IMAGE_NAME}..."
            "$RUNTIME" tag "spn-algo-octave-dev:latest" "$IMAGE_NAME"
        else
            echo "[dev.sh] Image ${IMAGE_NAME} not found. Building first..."
            build_image
        fi
    fi
}

CONTAINER_NAME="spn-generation-dev"

is_container_running() {
    "$RUNTIME" ps --filter "name=^/${CONTAINER_NAME}$" --filter "name=^${CONTAINER_NAME}$" --filter "status=running" --format "{{.Names}}" 2>/dev/null | grep -q "$CONTAINER_NAME"
}

start_daemon() {
    ensure_image
    if is_container_running; then
        echo "[dev.sh] Container ${CONTAINER_NAME} is already running."
        return 0
    fi
    # Remove any existing stopped/dead container with the same name
    "$RUNTIME" rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

    echo "[dev.sh] Starting persistent container ${CONTAINER_NAME}..."
    local extra_flags=()
    if [ "$RUNTIME" = "podman" ]; then
        extra_flags+=(--userns=keep-id)
    fi

    "$RUNTIME" run -d \
        --name "$CONTAINER_NAME" \
        "${extra_flags[@]}" \
        -v "${SCRIPT_DIR}:/workspace:z" \
        -w /workspace \
        "$IMAGE_NAME" \
        sleep infinity >/dev/null
    echo "[dev.sh] Container ${CONTAINER_NAME} started successfully."
}

stop_daemon() {
    if is_container_running; then
        echo "[dev.sh] Stopping persistent container ${CONTAINER_NAME}..."
        "$RUNTIME" stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        "$RUNTIME" rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        echo "[dev.sh] Container stopped."
    else
        echo "[dev.sh] Container ${CONTAINER_NAME} is not running."
    fi
}

run_container() {
    local tty_flag=""
    if [ -t 0 ] && [ -t 1 ]; then
        tty_flag="-it"
    elif [ -t 0 ]; then
        tty_flag="-i"
    fi

    if is_container_running; then
        exec "$RUNTIME" exec $tty_flag "$CONTAINER_NAME" "$@"
    fi

    ensure_image
    local extra_flags=()
    if [ "$RUNTIME" = "podman" ]; then
        extra_flags+=(--userns=keep-id)
    fi

    exec "$RUNTIME" run --rm $tty_flag \
        "${extra_flags[@]}" \
        -v "${SCRIPT_DIR}:/workspace:z" \
        -w /workspace \
        "$IMAGE_NAME" \
        "$@"
}


usage() {
    cat <<EOF
Usage: ./dev.sh <command> [arguments...]

Development helper for SPN-Algo-Octave (using ${RUNTIME}).

Commands:
  up                Start persistent background container (${CONTAINER_NAME})
  down              Stop persistent background container
  status            Show persistent container status
  build             Build the container image (${IMAGE_NAME})
  shell, bash       Open an interactive shell in the container
  octave [args...]  Run Octave inside the container ('octave --no-gui -q ...')
  run [args...]     Run the dataset generator ('octave --no-gui -q main.m ...')
  test              Run the test suite ('octave --no-gui -q tests/run_tests.m')
  bench             Run the benchmark suite ('octave --no-gui -q benchmarks/run_benchmarks.m')
  make [args...]    Run 'make' inside the container (e.g. for building C/C++ oct extensions)
  cmd <command...>  Execute an arbitrary command inside the container
  help              Show this help message

Environment variables:
  CONTAINER_TOOL    Force runtime: 'docker' or 'podman' (current: ${RUNTIME})
EOF
}

COMMAND="${1:-help}"
if [ $# -gt 0 ]; then
    shift
fi

case "$COMMAND" in
    up)
        start_daemon
        ;;
    down)
        stop_daemon
        ;;
    status)
        if is_container_running; then
            echo "[dev.sh] Container ${CONTAINER_NAME} is RUNNING."
        else
            echo "[dev.sh] Container ${CONTAINER_NAME} is NOT running."
        fi
        ;;
    build)
        build_image
        ;;

    shell|bash)
        run_container /bin/bash "$@"
        ;;
    octave)
        run_container octave --no-gui -q "$@"
        ;;
    run)
        run_container octave --no-gui -q main.m "$@"
        ;;
    test)
        run_container octave --no-gui -q --eval "run('tests/run_tests.m');" "$@"
        ;;
    bench)
        run_container octave --no-gui -q benchmarks/run_benchmarks.m "$@"
        ;;
    make)
        run_container make "$@"
        ;;
    cmd)
        if [ $# -eq 0 ]; then
            echo "Error: 'cmd' requires at least one argument." >&2
            exit 1
        fi
        run_container "$@"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Unknown command: $COMMAND" >&2
        usage >&2
        exit 1
        ;;
esac
