#!/usr/bin/env bash
# Configuration management for local-coder

# Initialize config (create default if not exists)
config_init() {
    ensure_dirs

    if [[ ! -f "$CONFIG_FILE" ]]; then
        debug "Creating default config at $CONFIG_FILE"
        config_create_default
    fi

    # Validate config
    if ! config_validate; then
        warn "Config validation failed, recreating..."
        config_create_default
    fi
}

# Create default configuration
config_create_default() {
    local default_config="$LOCAL_CODER_DIR/config/config.json"

    if [[ -f "$default_config" ]]; then
        cp "$default_config" "$CONFIG_FILE"
    else
        # Fallback: create minimal config
        cat > "$CONFIG_FILE" << EOF
{
  "server": {
    "binary": "$LLAMA_SERVER_DEFAULT",
    "host": "$DEFAULT_HOST",
    "port": $DEFAULT_PORT,
    "default_model": null,
    "threads": $DEFAULT_THREADS,
    "gpu_layers": $DEFAULT_GPU_LAYERS,
    "ctx_size": $DEFAULT_CTX_SIZE,
    "batch_size": $DEFAULT_BATCH_SIZE,
    "ubatch_size": $DEFAULT_UBATCH_SIZE
  },
  "paths": {
    "models": [
      "$HOME/.cache/llama.cpp",
      "$DATA_DIR/models"
    ],
    "logs": "$LOG_DIR",
    "pid": "$PID_DIR"
  },
  "opencode": {
    "config_path": "$HOME/.config/opencode/opencode.json",
    "provider": "llama.cpp"
  }
}
EOF
    fi

    chmod 600 "$CONFIG_FILE"
}

# Validate configuration
config_validate() {
    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        error "jq is required for config management. Install with: sudo apt install jq"
        return 1
    fi

    # Validate JSON syntax
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        return 1
    fi

    return 0
}

# Get config value using jq syntax
config_get() {
    local key="$1"

    # Ensure config exists
    [[ -f "$CONFIG_FILE" ]] || config_init

    jq -r "$key" "$CONFIG_FILE" 2>/dev/null
}

# Set config value using jq syntax
config_set() {
    local key="$1"
    local value="$2"

    # Ensure config exists
    [[ -f "$CONFIG_FILE" ]] || config_init

    # Update config
    local tmp_file
    tmp_file=$(mktemp)
    jq "$key = \"$value\"" "$CONFIG_FILE" > "$tmp_file" && mv "$tmp_file" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    debug "Set config: $key = $value"
}

# Get all config as JSON
config_get_all() {
    [[ -f "$CONFIG_FILE" ]] || config_init
    cat "$CONFIG_FILE"
}

# Show configuration (for CLI command)
cmd_config_show() {
    config_init
    header "Configuration"
    jq '.' "$CONFIG_FILE"
}

# Get specific config value (for CLI command)
cmd_config_get() {
    local key="$1"

    if [[ -z "$key" ]]; then
        error "Usage: local-coder config get <key>"
        error "Example: local-coder config get .server.port"
        exit 1
    fi

    config_init
    config_get "$key"
}

# Set config value (for CLI command)
cmd_config_set() {
    local key="$1"
    local value="$2"

    if [[ -z "$key" ]] || [[ -z "$value" ]]; then
        error "Usage: local-coder config set <key> <value>"
        error "Example: local-coder config set .server.port 8082"
        exit 1
    fi

    config_init
    config_set "$key" "$value"
    success "Configuration updated: $key = $value"
}

# Edit config in editor
cmd_config_edit() {
    config_init

    local editor="${EDITOR:-vi}"
    info "Opening $CONFIG_FILE in $editor..."
    "$editor" "$CONFIG_FILE"

    # Validate after edit
    if ! config_validate; then
        error "Invalid JSON in config file. Please fix and try again."
        exit 1
    fi

    success "Configuration saved"
}

# Get server binary path
config_get_server_binary() {
    config_get ".server.binary"
}

# Get server host
config_get_server_host() {
    config_get ".server.host"
}

# Get server port
config_get_server_port() {
    config_get ".server.port"
}

# Get default model
config_get_default_model() {
    config_get ".server.default_model"
}

# Set default model
config_set_default_model() {
    local model="$1"
    config_set ".server.default_model" "$model"
}

# Get model paths
config_get_model_paths() {
    config_get ".paths.models[]"
}

# Get log directory
config_get_log_dir() {
    local log_dir
    log_dir=$(config_get ".paths.logs")
    echo "${log_dir/#\~/$HOME}"
}

# Get PID directory
config_get_pid_dir() {
    local pid_dir
    pid_dir=$(config_get ".paths.pid")
    echo "${pid_dir/#\~/$HOME}"
}

# Get server URL
config_get_server_url() {
    local host
    local port
    host=$(config_get_server_host)
    port=$(config_get_server_port)
    echo "http://$host:$port/v1"
}

# Check if config is initialized
config_is_initialized() {
    [[ -f "$CONFIG_FILE" ]] && config_validate
}

# Export functions
export -f config_init config_create_default config_validate
export -f config_get config_set config_get_all
export -f cmd_config_show cmd_config_get cmd_config_set cmd_config_edit
export -f config_get_server_binary config_get_server_host config_get_server_port
export -f config_get_default_model config_set_default_model
export -f config_get_model_paths config_get_log_dir config_get_pid_dir
export -f config_get_server_url config_is_initialized
