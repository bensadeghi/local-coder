#!/usr/bin/env bash
# Server lifecycle management for local-coder

# PID file for server
SERVER_PID_FILE="$PID_DIR/server.pid"

# Get server PID from pidfile
server_get_pid() {
    if [[ -f "$SERVER_PID_FILE" ]]; then
        cat "$SERVER_PID_FILE"
    fi
}

# Check if server is running
server_is_running() {
    local pid
    pid=$(server_get_pid)

    if [[ -z "$pid" ]]; then
        return 1
    fi

    # Check if process exists
    if kill -0 "$pid" 2>/dev/null; then
        return 0
    else
        # Clean up stale pidfile
        rm -f "$SERVER_PID_FILE"
        return 1
    fi
}

# Health check for server HTTP endpoint
server_health_check() {
    local max_attempts="${1:-30}"
    local timeout="${2:-1}"

    local url
    url=$(config_get_server_url)

    local attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s -f "$url/models" >/dev/null 2>&1; then
            return 0
        fi
        sleep "$timeout"
        attempt=$((attempt + 1))
    done

    return 1
}

# Wait for server to be ready
server_wait_ready() {
    info "Waiting for server to be ready..."

    if server_health_check 30 1; then
        success "Server is ready"
        return 0
    else
        error "Server failed to start or not responding"
        return 1
    fi
}

# Find model by name or partial match
server_find_model() {
    local model_name="$1"

    # If exact file path
    if [[ -f "$model_name" ]]; then
        echo "$model_name"
        return 0
    fi

    # Search in model directories
    for dir in $(config_get_model_paths); do
        dir="${dir/#\~/$HOME}"

        # Exact match
        if [[ -f "$dir/$model_name.gguf" ]]; then
            echo "$dir/$model_name.gguf"
            return 0
        fi

        if [[ -f "$dir/$model_name" ]]; then
            echo "$dir/$model_name"
            return 0
        fi

        # Partial match (search for *name*.gguf)
        local found
        found=$(find "$dir" -maxdepth 1 -name "*${model_name}*.gguf" -type f 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            echo "$found"
            return 0
        fi
    done

    return 1
}

# Get default model or first available
server_get_default_model() {
    # Check configured default
    local default
    default=$(config_get_default_model)

    if [[ -n "$default" && "$default" != "null" ]]; then
        local model_path
        model_path=$(server_find_model "$default")
        if [[ -n "$model_path" ]]; then
            echo "$model_path"
            return 0
        fi
    fi

    # Return first available model
    for dir in $(config_get_model_paths); do
        dir="${dir/#\~/$HOME}"
        local first_model
        first_model=$(find "$dir" -maxdepth 1 -name "*.gguf" -type f 2>/dev/null | head -1)
        if [[ -n "$first_model" ]]; then
            echo "$first_model"
            return 0
        fi
    done

    return 1
}

# Parse command-line options for server start
server_parse_options() {
    # Returns variables: opt_ctx_size, opt_gpu_layers, opt_threads
    opt_ctx_size=""
    opt_gpu_layers=""
    opt_threads=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ctx-size)
                opt_ctx_size="$2"
                shift 2
                ;;
            --gpu-layers)
                opt_gpu_layers="$2"
                shift 2
                ;;
            --threads)
                opt_threads="$2"
                shift 2
                ;;
            *)
                # Not an option, return
                break
                ;;
        esac
    done
}

# Start server
server_start() {
    local model_name=""
    local ctx_size_override=""
    local gpu_layers_override=""
    local threads_override=""
    local n_cpu_moe_override=""

    # Parse arguments: model name and optional flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ctx-size)
                ctx_size_override="$2"
                shift 2
                ;;
            --gpu-layers)
                gpu_layers_override="$2"
                shift 2
                ;;
            --threads)
                threads_override="$2"
                shift 2
                ;;
            --n-cpu-moe)
                n_cpu_moe_override="$2"
                shift 2
                ;;
            -*)
                error "Unknown option: $1"
                info "Valid options: --ctx-size N, --gpu-layers N, --threads N, --n-cpu-moe N"
                return 1
                ;;
            *)
                # This is the model name
                model_name="$1"
                shift
                ;;
        esac
    done

    # Check if already running
    if server_is_running; then
        warn "Server is already running (PID: $(server_get_pid))"
        return 0
    fi

    # Find model
    local model_path
    if [[ -n "$model_name" ]]; then
        model_path=$(server_find_model "$model_name")
        if [[ -z "$model_path" ]]; then
            error "Model not found: $model_name"
            info "Available models:"
            cmd_models_list
            return 1
        fi
    else
        model_path=$(server_get_default_model)
        if [[ -z "$model_path" ]]; then
            error "No models found. Please download a model first."
            info "Try: local-coder models download <url>"
            return 1
        fi
    fi

    # Get config values (with CLI overrides)
    local binary
    local host
    local port
    local threads
    local gpu_layers
    local n_cpu_moe
    local ctx_size
    local batch_size
    local ubatch_size
    local log_file

    binary=$(config_get_server_binary)
    host=$(config_get_server_host)
    port=$(config_get_server_port)
    threads=${threads_override:-$(config_get ".server.threads")}
    gpu_layers=${gpu_layers_override:-$(config_get ".server.gpu_layers")}
    n_cpu_moe=${n_cpu_moe_override:-$(config_get ".server.n_cpu_moe // 0")}
    ctx_size=${ctx_size_override:-$(config_get ".server.ctx_size")}
    batch_size=$(config_get ".server.batch_size")
    ubatch_size=$(config_get ".server.ubatch_size")
    log_file=$(config_get_log_dir)/server.log

    # Validate binary exists
    if [[ ! -f "$binary" ]]; then
        error "llama-server binary not found: $binary"
        info "Build llama.cpp first:"
        info "  cd ~/repos/llama.cpp && cmake -B build -DLLAMA_CUDA=ON && cmake --build build"
        return 1
    fi

    # Start server
    info "Starting llama-server..."
    kv "Model" "$(basename "$model_path")"
    kv "Host" "$host"
    kv "Port" "$port"

    # Show overrides
    if [[ -n "$ctx_size_override" ]]; then
        kv "Context Size" "$ctx_size (override)"
    fi
    if [[ -n "$gpu_layers_override" ]]; then
        kv "GPU Layers" "$gpu_layers (override)"
    fi
    if [[ -n "$n_cpu_moe_override" && "$n_cpu_moe" != "0" ]]; then
        kv "CPU MoE Layers" "$n_cpu_moe (override)"
    fi
    if [[ -n "$threads_override" ]]; then
        kv "Threads" "$threads (override)"
    fi

    # Build command
    local cmd=(
        "$binary"
        --model "$model_path"
        --host "$host"
        --port "$port"
        --threads "$threads"
        --gpu-layers "$gpu_layers"
        --ctx-size "$ctx_size"
        --batch-size "$batch_size"
        --ubatch-size "$ubatch_size"
        --log-file "$log_file"
    )

    # Add n-cpu-moe if specified
    if [[ -n "$n_cpu_moe" && "$n_cpu_moe" != "0" ]]; then
        cmd+=(--n-cpu-moe "$n_cpu_moe")
    fi

    debug "Running: ${cmd[*]}"

    # Start in background
    "${cmd[@]}" >/dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "$SERVER_PID_FILE"

    # Wait for server to be ready
    if server_wait_ready; then
        success "Server started (PID: $pid)"
        info "API endpoint: $(config_get_server_url)"
        return 0
    else
        error "Server failed to start. Check logs: $log_file"
        return 1
    fi
}

# Stop server
server_stop() {
    if ! server_is_running; then
        info "Server is not running"
        return 0
    fi

    local pid
    pid=$(server_get_pid)

    info "Stopping server (PID: $pid)..."
    kill "$pid" 2>/dev/null

    # Wait for process to end
    local count=0
    while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
        sleep 1
        count=$((count + 1))
    done

    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
        warn "Server did not stop gracefully, forcing..."
        kill -9 "$pid" 2>/dev/null
    fi

    rm -f "$SERVER_PID_FILE"
    success "Server stopped"
}

# Restart server
server_restart() {
    server_stop
    sleep 1
    server_start "$1"
}

# Show server status
server_status() {
    header "Server Status"

    if server_is_running; then
        local pid
        pid=$(server_get_pid)
        success "Running"

        kv "PID" "$pid"
        kv "Endpoint" "$(config_get_server_url)"

        # Try to get loaded model info
        local url
        url=$(config_get_server_url)
        local model_info
        model_info=$(curl -s "$url/models" 2>/dev/null | jq -r '.data[0].id // "unknown"' 2>/dev/null)

        if [[ -n "$model_info" && "$model_info" != "unknown" ]]; then
            kv "Model" "$model_info"
        fi

        # Show memory usage if GPU is available
        if command -v nvidia-smi &>/dev/null; then
            local gpu_mem
            gpu_mem=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
            if [[ -n "$gpu_mem" ]]; then
                kv "GPU Memory" "$gpu_mem MiB"
            fi
        fi
    else
        warn "Stopped"
    fi

    echo ""
    header "Configuration"
    kv "Binary" "$(config_get_server_binary)"
    kv "Host" "$(config_get_server_host)"
    kv "Port" "$(config_get_server_port)"
    kv "Default Model" "$(config_get_default_model || "none")"
}

# Show server logs
server_logs() {
    local follow="$1"
    local log_file
    log_file=$(config_get_log_dir)/server.log

    if [[ ! -f "$log_file" ]]; then
        info "No log file found"
        return 0
    fi

    if [[ "$follow" == "tail" || "$follow" == "-f" || "$follow" == "--follow" ]]; then
        tail -f "$log_file"
    else
        tail -100 "$log_file"
    fi
}

# CLI command handlers
cmd_start() {
    config_init
    server_start "$1"
}

cmd_stop() {
    config_init
    server_stop
}

cmd_restart() {
    config_init
    server_restart "$1"
}

cmd_status() {
    config_init
    server_status
}

cmd_logs() {
    config_init
    server_logs "$1"
}

# Export functions
export -f server_get_pid server_is_running server_health_check
export -f server_wait_ready server_find_model server_get_default_model
export -f server_start server_stop server_restart server_status server_logs
export -f cmd_start cmd_stop cmd_restart cmd_status cmd_logs
