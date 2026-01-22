#!/usr/bin/env bash
# local-coder library loader
# This file sets up common paths and variables for all library modules

# Determine paths
LOCAL_CODER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Configuration paths
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/local-coder"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/local-coder"
CONFIG_FILE="$CONFIG_DIR/config.json"
MODELS_INDEX_FILE="$DATA_DIR/models/index.json"

# Default paths (can be overridden by config)
LLAMA_SERVER_DEFAULT="$HOME/repos/llama.cpp/build/bin/llama-server"
MODELS_DIRS=(
    "$HOME/.cache/llama.cpp"
    "$DATA_DIR/models"
)
LOG_DIR="$DATA_DIR/logs"
PID_DIR="$DATA_DIR/pid"

# Server defaults
DEFAULT_HOST="127.0.0.1"
DEFAULT_PORT=8081
DEFAULT_THREADS=-1
DEFAULT_GPU_LAYERS=99
DEFAULT_CTX_SIZE=0
DEFAULT_BATCH_SIZE=2048
DEFAULT_UBATCH_SIZE=512

# Colors (will be used by ui.sh)
if [[ -t 1 ]] && [[ -z "$NO_COLOR" ]]; then
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_MAGENTA='\033[0;35m'
    COLOR_CYAN='\033[0;36m'
    COLOR_BOLD='\033[1m'
    COLOR_RESET='\033[0m'
else
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_MAGENTA=''
    COLOR_CYAN=''
    COLOR_BOLD=''
    COLOR_RESET=''
fi

# Ensure directories exist
ensure_dirs() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DATA_DIR/models"
    mkdir -p "$LOG_DIR"
    mkdir -p "$PID_DIR"
}

# Export for use in other modules
export LOCAL_CODER_DIR
export CONFIG_DIR
export DATA_DIR
export CONFIG_FILE
export MODELS_INDEX_FILE
export LLAMA_SERVER_DEFAULT
export MODELS_DIRS
export LOG_DIR
export PID_DIR
export DEFAULT_HOST
export DEFAULT_PORT
export DEFAULT_THREADS
export DEFAULT_GPU_LAYERS
export DEFAULT_CTX_SIZE
export DEFAULT_BATCH_SIZE
export DEFAULT_UBATCH_SIZE
export COLOR_RED COLOR_GREEN COLOR_YELLOW COLOR_BLUE
export COLOR_MAGENTA COLOR_CYAN COLOR_BOLD COLOR_RESET
