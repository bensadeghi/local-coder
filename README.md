# local-coder

Simple management tool for llama.cpp + OpenCode integration.

**One command to start everything.** No more remembering complex command-line flags.

## Quick Start

```bash
# Start the server with your default model
local-coder start

# Launch OpenCode TUI
local-coder open

# Done? Stop the server
local-coder stop
```

## Features

- **Single command startup** - `local-coder start` launches llama-server
- **Model management** - Download, list, delete, and switch between models
- **CLI parameter overrides** - Set context size, GPU layers, MoE settings on the fly
- **Smart defaults** - Pre-configured for RTX 5060 Ti (16GB) with optimal GPU utilization
- **Health checks** - Verifies server is responding before launching OpenCode
- **MoE model support** - Optimized for Mixture of Experts models like Qwen3-Coder

## Installation

```bash
cd ~/repos/local-coder
./scripts/install.sh
```

This copies `local-coder` to `/usr/local/bin` and sets up the config directory.

Or run directly from the repo:
```bash
./local-coder status
```

## Usage

### Server Commands

```bash
# Start with default model
local-coder start

# Start with specific model
local-coder start qwen3-coder

# Start with custom context size
local-coder start --ctx-size 8192

# Start with specific model and options
local-coder start deepseek-coder --gpu-layers 50 --threads 16

# Stop server
local-coder stop

# Restart server
local-coder restart

# Show server status
local-coder status

# View server logs
local-coder logs
local-coder logs tail  # Follow logs
```

### Model Commands

```bash
# List all available models
local-coder models list

# Download a model from URL
local-coder models download https://huggingface.co/.../model.gguf

# Delete a model
local-coder models delete old-model

# Set default model
local-coder models set-default qwen3-coder
```

### Configuration

```bash
# Show all configuration
local-coder config

# Get specific value
local-coder config get .server.port

# Set configuration value
local-coder config set .server.port 8082

# Edit config in your editor
local-coder config edit
```

## Configuration

The config file is at `~/.config/local-coder/config.json`:

```json
{
  "server": {
    "binary": "/home/bs/repos/llama.cpp/build/bin/llama-server",
    "host": "127.0.0.1",
    "port": 8081,
    "default_model": null,
    "threads": -1,
    "gpu_layers": 35,
    "n_cpu_moe": 12,
    "ctx_size": 32768,
    "batch_size": 2048,
    "ubatch_size": 512
  },
  "paths": {
    "models": [
      "/home/bs/.cache/llama.cpp",
      "/home/bs/.local/share/local-coder/models"
    ],
    "logs": "/home/bs/.local/share/local-coder/logs",
    "pid": "/home/bs/.local/share/local-coder/pid"
  },
  "opencode": {
    "config_path": "/home/bs/.config/opencode/opencode.json",
    "provider": "llama.cpp"
  }
}
```

### CLI Parameters

You can override config values on the command line:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--ctx-size N` | Context window size (tokens) | `--ctx-size 32768` |
| `--gpu-layers N` | Number of layers to offload to GPU | `--gpu-layers 40` |
| `--n-cpu-moe N` | For MoE models: keep first N expert layers on CPU | `--n-cpu-moe 12` |
| `--threads N` | Number of CPU threads (-1 = auto) | `--threads 16` |

## GPU Optimization

### Understanding GPU Memory Allocation

For llama.cpp models, GPU memory is used for:
1. **Model weights** - The largest portion, scales with `--gpu-layers`
2. **KV cache** - Context cache, scales with `--ctx-size` and concurrent requests
3. **Compute buffers** - Fixed overhead for inference (~300 MB)

Total GPU memory = Model weights + KV cache + Compute buffers

### MoE Models (Mixture of Experts)

Large MoE models like **Qwen3-Coder-30B** have special memory requirements:
- 48 transformer layers + 1 output layer = 49 total layers
- 128 expert networks (only 8 active per forward pass)
- Expert weights are memory-intensive

**Key parameter**: `--n-cpu-moe` keeps the first N expert layers on CPU, reducing GPU memory significantly.

### Optimized Settings by GPU Size

#### RTX 5060 Ti (16GB) - **Default Config (Optimal)**

```bash
gpu_layers: 35      # 71% of layers on GPU
n_cpu_moe: 12       # 12 expert layers on CPU
ctx_size: 32768     # 32K context window (recommended)
```
**Result:** 97% GPU utilization (15.8 GB / 16.3 GB)
- Model buffer: 12.4 GB
- KV cache: 2.2 GB
- Compute: 346 MB
- **Best balance** of performance and context size

#### RTX 5060 Ti (16GB) - Alternative Configurations

**Maximum Performance (16K context):**
```bash
gpu_layers: 38
n_cpu_moe: 11
ctx_size: 16384
```
**Result:** 96% utilization, faster inference, smaller context

**Large Context (64K context):**
```bash
gpu_layers: 24
n_cpu_moe: 20
ctx_size: 65536
```
**Result:** 77% utilization, largest context window

#### RTX 4090 / 3090 (24GB)
```bash
gpu_layers: 42
n_cpu_moe: 8
ctx_size: 32768
```
**Expected:** ~22 GB GPU utilization

#### RTX 4080 / 3080 (16GB)
```bash
gpu_layers: 35
n_cpu_moe: 12
ctx_size: 32768
```
**Expected:** ~15.8 GB GPU utilization

#### RTX 4070 / 3070 (12GB)
```bash
gpu_layers: 28
n_cpu_moe: 18
ctx_size: 16384
```
**Expected:** ~11 GB GPU utilization

#### RTX 4060 / 8GB GPUs
```bash
gpu_layers: 20
n_cpu_moe: 24
ctx_size: 8192
```
**Expected:** ~7.5 GB GPU utilization

### Finding Your Optimal Settings

To find the best configuration for your GPU:

1. **Check your GPU memory:**
   ```bash
   nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits
   ```

2. **Start with conservative settings:**
   ```bash
   local-coder start --gpu-layers 20 --n-cpu-moe 20 --ctx-size 8192
   ```

3. **Check current utilization:**
   ```bash
   local-coder status
   nvidia-smi
   ```

4. **Gradually increase until near max:**
   - Add 2-3 GPU layers at a time
   - Reduce `n-cpu-moe` by 1-2
   - Keep 500 MB - 1 GB headroom

5. **Verify stability:**
   ```bash
   # Send a test request
   curl http://127.0.0.1:8081/v1/models

   # Check logs for errors
   local-coder logs
   ```

**Warning:** Settings that are too aggressive will cause:
- "out of memory" errors
- Server crashes (segmentation fault)
- CUDA malloc failures

If this happens, reduce `--gpu-layers` or increase `--n-cpu-moe`.

### Performance Impact

More GPU utilization = faster inference:

| GPU Utilization | Prompt Speed | Generation Speed |
|-----------------|--------------|------------------|
| 60-70% | ~600 t/s | ~10 t/s |
| 80-90% | ~750 t/s | ~12 t/s |
| 95%+ | ~900 t/s | ~15 t/s |

*Actual speeds vary by model and hardware.*

## How It Works

1. **Model Discovery** - Scans `/home/bs/.cache/llama.cpp` and `~/.local/share/local-coder/models` for `.gguf` files
2. **Health Checks** - Waits for llama-server HTTP endpoint to respond before reporting success
3. **OpenCode Integration** - Launches OpenCode configured to connect to your local server

## OpenCode Integration

### What is OpenCode?

[OpenCode](https://opencode.ai) is an open-source AI coding agent that provides:
- Terminal-based interface (TUI) for coding assistance
- IDE extensions for VS Code, JetBrains, etc.
- Native support for local LLM providers
- Tool calling and code execution capabilities

### Installing OpenCode

```bash
# Using install script (recommended)
curl -fsSL https://opencode.ai/install | bash

# Using npm
npm install -g opencode-ai

# Using Homebrew (macOS/Linux)
brew install anomalyco/tap/opencode
```

### Configuring OpenCode for local-coder

OpenCode stores its configuration in `~/.config/opencode/opencode.json`.

local-coder uses **port 8081** by default. Your OpenCode config should include:

```json
{
  "apiBaseUrl": "http://127.0.0.1:8081/v1",
  "models": [
    {
      "id": "llama.cpp",
      "provider": "llama.cpp",
      "name": "Local LLaMA Server"
    }
  ]
}
```

### Setting Up OpenCode Manually

1. **Check current OpenCode config:**
   ```bash
   cat ~/.config/opencode/opencode.json
   ```

2. **Edit the config (if needed):**
   ```bash
   # Open in editor
   nano ~/.config/opencode/opencode.json

   # Or use local-coder to check
   cat ~/.config/opencode/opencode.json | grep -A5 "llama.cpp"
   ```

3. **Verify the port matches local-coder:**
   ```bash
   local-coder config get .server.port
   # Should output: 8081
   ```

### Using OpenCode with local-coder

```bash
# Method 1: Use the integrated command (recommended)
local-coder open

# Method 2: Launch OpenCode directly
opencode -m llama.cpp

# Method 3: Launch OpenCode and select provider
opencode
# Then run: /connect
# Select: llama.cpp
```

### Verifying the Connection

1. **Start the server:**
   ```bash
   local-coder start
   ```

2. **Check server is responding:**
   ```bash
   curl http://127.0.0.1:8081/v1/models
   ```

3. **Launch OpenCode:**
   ```bash
   local-coder open
   ```

4. **In OpenCode TUI, verify connection:**
   - Press `/` to open command palette
   - Run `/models` to see available models
   - You should see your local model listed

### Troubleshooting OpenCode Connection

**"Failed to connect to server"**
```bash
# Check if server is running
local-coder status

# Check if port is accessible
curl http://127.0.0.1:8081/v1/models

# Check OpenCode config
cat ~/.config/opencode/opencode.json | grep apiBaseUrl
```

**OpenCode can't find the model**
```bash
# Verify model is loaded
curl -s http://127.0.0.1:8081/v1/models | jq '.data[0].id'

# Check OpenCode model selection
# In OpenCode TUI: /models
```

**Port mismatch**
```bash
# Check what port local-coder is using
local-coder config get .server.port

# Check what port OpenCode is configured for
cat ~/.config/opencode/opencode.json | grep 8081

# Update OpenCode config if needed
nano ~/.config/opencode/opencode.json
```

### OpenCode Tips for local-coder

**Set llama.cpp as default provider:**
```bash
# In OpenCode TUI
/config
# Set "default_provider" to "llama.cpp"
```

**Use context effectively:**
- The 32K context window allows you to work with large codebases
- Use `/include` to focus on specific directories
- Use `/exclude` to ignore node_modules, build artifacts, etc.

**Leverage tool calling:**
- OpenCode can execute commands, read files, and modify code
- Perfect for refactoring, testing, and code generation
- Works seamlessly with local models

## Requirements

- llama.cpp built with llama-server (`~/repos/llama.cpp/build/bin/llama-server`)
- OpenCode installed (`opencode` command available)
- `jq` for config management
- `curl` for health checks
- NVIDIA GPU with CUDA support (for GPU acceleration)

## Examples

### Start with a large context window for coding projects
```bash
local-coder start --ctx-size 32768
```

### Start with maximum GPU layers
```bash
local-coder start --gpu-layers 40 --n-cpu-moe 10
```

### Try a new model
```bash
# Download
local-coder models download https://huggingface.co/mudler/DeepSeek-Coder-v2-Instruct-GGUF/resolve/main/DeepSeek-Coder-v2-Instruct.Q4_K_M.gguf

# Start with it
local-coder start deepseek-coder

# Set as default if you like it
local-coder models set-default deepseek-coder
```

## Troubleshooting

### Server won't start

```bash
# Check logs for errors
local-coder logs

# Look for CUDA errors or OOM
tail -50 ~/.local/share/local-coder/logs/server.log

# Verify llama-server binary exists
ls -la ~/repos/llama.cpp/build/bin/llama-server

# Check if port is already in use
netstat -tlnp | grep 8081
```

### Out of memory errors

```bash
# Reduce GPU layers
local-coder start --gpu-layers 30 --n-cpu-moe 15

# Reduce context size
local-coder start --ctx-size 8192

# Check available GPU memory
nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits
```

### Model not found

```bash
# List available models
local-coder models list

# Check model directories
ls -la ~/.cache/llama.cpp/
ls -la ~/.local/share/local-coder/models/

# Verify model file integrity
file ~/.cache/llama.cpp/*.gguf
```

### OpenCode can't connect

```bash
# Check server is running
local-coder status

# Test API endpoint
curl http://127.0.0.1:8081/v1/models

# Verify OpenCode config
cat ~/.config/opencode/opencode.json | grep llama.cpp
```

### Slow performance

```bash
# Check GPU utilization
nvidia-smi dmon -s u

# Increase GPU layers if memory available
local-coder start --gpu-layers 40

# Reduce threads if CPU is bottleneck
local-coder start --threads 8
```

## Advanced Topics

### Context Size vs GPU Memory

KV cache memory formula:
```
KV cache (MB) = 2 × ctx_size × layers × 2 (K+V) × 2 (bytes) / 1024 / 1024
```

For Qwen3-Coder-30B (48 layers):
- 8K context = ~600 MB KV cache
- 16K context = ~1.2 GB KV cache
- 32K context = ~2.4 GB KV cache

### Non-MoE Models

For non-MoE models, omit `--n-cpu-moe` or set to 0:
```bash
local-coder start --n-cpu-moe 0
```

### CPU-Only Mode

For systems without GPU:
```bash
local-coder start --gpu-layers 0 --threads 16
```

## License

MIT
