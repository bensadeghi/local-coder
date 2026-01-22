#!/usr/bin/env bash
# Model management for local-coder

# Scan for GGUF models in configured directories
models_scan() {
    local models=()

    for dir in $(config_get_model_paths); do
        dir="${dir/#\~/$HOME}"

        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' model; do
                models+=("$model")
            done < <(find "$dir" -maxdepth 1 -name "*.gguf" -type f -print0 2>/dev/null)
        fi
    done

    printf '%s\n' "${models[@]}"
}

# Get model info (filename, size)
models_get_info() {
    local model_path="$1"

    if [[ ! -f "$model_path" ]]; then
        return 1
    fi

    local filename
    local size

    filename=$(basename "$model_path")
    size=$(stat -f%z "$model_path" 2>/dev/null || stat -c%s "$model_path" 2>/dev/null)

    echo "$filename|$size"
}

# Parse model name from filename (extract clean name)
models_parse_name() {
    local filename="$1"
    local name

    # Remove .gguf extension
    name="${filename%.gguf}"

    # Remove common prefixes
    name="${name#unsloth_}"
    name="${name#vllm-}"

    # Remove repo name if present (e.g., "Repo_Model_Q4_K_M")
    name=$(echo "$name" | sed 's/^[^=]*=//')

    # Clean up underscores
    name=$(echo "$name" | sed 's/_-/ /g')

    echo "$name"
}

# List all models
cmd_models_list() {
    config_init

    local verbose=false
    if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
        verbose=true
    fi

    header "Available Models"

    local models
    mapfile -t models < <(models_scan)

    if [[ ${#models[@]} -eq 0 ]]; then
        warn "No models found"
        info "Model directories:"
        for dir in $(config_get_model_paths); do
            echo "  - $dir"
        done
        info "Download a model with: local-coder models download <url>"
        return 0
    fi

    # Print table header
    if $verbose; then
        printf "  %-50s %12s  %s\n" "Name" "Size" "Path"
        divider "--------------------------------------------------------------------------------"
    else
        printf "  %-50s %12s\n" "Name" "Size"
        divider "-------------------------------------------------------"
    fi

    for model in "${models[@]}"; do
        local info
        info=$(models_get_info "$model")
        IFS='|' read -r filename size <<< "$info"

        local name
        local size_human

        name=$(models_parse_name "$filename")
        size_human=$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "${size}B")

        if $verbose; then
            printf "  %-50s %12s  %s\n" "$name" "$size_human" "$model"
        else
            printf "  %-50s %12s\n" "$name" "$size_human"
        fi
    done

    echo ""
    info "Total: ${#models[@]} model(s)"
}

# Download model
cmd_models_download() {
    local url="$1"

    if [[ -z "$url" ]]; then
        error "Usage: local-coder models download <url>"
        info "Example: local-coder models download https://huggingface.co/.../model.gguf"
        exit 1
    fi

    config_init

    local output_dir
    output_dir=$(config_get_model_paths | head -1)
    output_dir="${output_dir/#\~/$HOME}"

    mkdir -p "$output_dir"

    # Determine filename from URL
    local filename
    filename=$(basename "$url" | sed 's/?.*//')

    if [[ -z "$filename" ]]; then
        error "Could not determine filename from URL"
        exit 1
    fi

    local output_path="$output_dir/$filename"

    # Check if already exists
    if [[ -f "$output_path" ]]; then
        if confirm "Model already exists at $output_path. Download again?" "n"; then
            rm -f "$output_path"
        else
            info "Download cancelled"
            return 0
        fi
    fi

    # Download
    info "Downloading model..."
    kv "URL" "$url"
    kv "Output" "$output_path"

    if curl -L --progress-bar "$url" -o "$output_path"; then
        echo ""

        # Verify GGUF format
        if file "$output_path" | grep -qv "GGUF"; then
            warn "Downloaded file may not be a valid GGUF model"
        fi

        success "Model downloaded successfully"

        # Ask if should be set as default
        local model_name
        model_name=$(models_parse_name "$filename")

        if confirm "Set '$model_name' as default model?" "y"; then
            config_set_default_model "$model_name"
            success "Default model set to: $model_name"
        fi
    else
        error "Download failed"
        rm -f "$output_path"
        exit 1
    fi
}

# Delete model
cmd_models_delete() {
    local model_name="$1"

    if [[ -z "$model_name" ]]; then
        error "Usage: local-coder models delete <model>"
        exit 1
    fi

    config_init

    local model_path
    model_path=$(server_find_model "$model_name")

    if [[ -z "$model_path" ]]; then
        error "Model not found: $model_name"
        return 1
    fi

    # Confirm deletion
    if ! confirm "Delete model: $model_path?" "n"; then
        info "Deletion cancelled"
        return 0
    fi

    rm -f "$model_path"
    success "Model deleted: $model_path"

    # Update default if this was the default
    local default
    default=$(config_get_default_model)
    if [[ "$default" == "$(models_parse_name "$model_path")" ]]; then
        config_set ".server.default_model" "null"
        info "Default model cleared (was deleted)"
    fi
}

# Set default model
cmd_models_set_default() {
    local model_name="$1"

    if [[ -z "$model_name" ]]; then
        error "Usage: local-coder models set-default <model>"
        exit 1
    fi

    config_init

    local model_path
    model_path=$(server_find_model "$model_name")

    if [[ -z "$model_path" ]]; then
        error "Model not found: $model_name"
        info "Available models:"
        cmd_models_list
        return 1
    fi

    local clean_name
    clean_name=$(models_parse_name "$(basename "$model_path")")

    config_set_default_model "$clean_name"
    success "Default model set to: $clean_name"
}

# Export functions
export -f models_scan models_get_info models_parse_name
export -f cmd_models_list cmd_models_download cmd_models_delete cmd_models_set_default
