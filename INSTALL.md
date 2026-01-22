# Installation Guide for local-coder

This guide covers detailed installation steps for local-coder.

## Prerequisites

### Required Software

1. **llama.cpp** - Built with CUDA support
   ```bash
   cd ~/repos/llama.cpp
   cmake -B build -DLLAMA_CUDA=ON
   cmake --build build --config Release
   ```

2. **OpenCode** - AI coding agent
   ```bash
   curl -fsSL https://opencode.ai/install | bash
   # or: npm install -g opencode-ai
   ```

3. **System utilities**
   ```bash
   # Ubuntu/Debian
   sudo apt install jq curl

   # Arch Linux
   sudo pacman -S jq curl
   ```

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| GPU | 8 GB VRAM | 16+ GB VRAM |
| RAM | 16 GB | 32 GB |
| Storage | 20 GB | 50+ GB (for multiple models) |

### Supported GPUs

- NVIDIA RTX 50-series (RTX 5060 Ti, RTX 5070, RTX 5080, RTX 5090)
- NVIDIA RTX 40-series (RTX 4060, RTX 4070, RTX 4080, RTX 4090)
- NVIDIA RTX 30-series (RTX 3060, RTX 3070, RTX 3080, RTX 3090)
- NVIDIA GTX 16-series (GTX 1660 Ti, etc.)

Older GPUs may work but with reduced performance.

## Installation Methods

### Method 1: System-Wide Installation (Recommended)

```bash
cd ~/repos/local-coder
./scripts/install.sh
```

This:
- Copies `local-coder` to `/usr/local/bin`
- Creates config directory at `~/.config/local-coder`
- Creates data directory at `~/.local/share/local-coder`
- Sets up default configuration

Requires write access to `/usr/local/bin` (may need sudo).

### Method 2: User-Only Installation

```bash
cd ~/repos/local-coder
mkdir -p ~/.local/bin
cp local-coder ~/.local/bin/

# Add to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Method 3: Run from Repository

```bash
cd ~/repos/local-coder
./local-coder status
```

No installation required, but you must be in the repository directory.

## Verification

Test that local-coder is installed correctly:

```bash
# Check version
local-coder version

# Show help
local-coder help

# Check status
local-coder status

# List models
local-coder models list
```

## Initial Configuration

On first run, local-coder creates a default configuration at:
```
~/.config/local-coder/config.json
```

To customize for your hardware:

1. **Check your GPU memory:**
   ```bash
   nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits
   ```

2. **Edit the config:**
   ```bash
   local-coder config edit
   ```

3. **Or set values directly:**
   ```bash
   local-coder config set .server.gpu_layers 35
   local-coder config set .server.n_cpu_moe 12
   local-coder config set .server.ctx_size 32768
   ```

See the [README](README.md#gpu-optimization) for recommended settings by GPU size.

## Model Setup

### Using Existing Models

If you have models in llama.cpp's default cache:
```
~/.cache/llama.cpp/
```

local-coder will automatically discover them.

### Adding New Models

```bash
# Create model directory
mkdir -p ~/.local/share/local-coder/models

# Download a model
local-coder models download https://huggingface.co/.../model.gguf

# Or manually copy
cp /path/to/model.gguf ~/.local/share/local-coder/models/
```

### Recommended Models

For coding assistance:
- **Qwen3-Coder-30B-A3B-Instruct** (18GB) - Best for code generation
- **DeepSeek-Coder-v2-Instruct** (4-7GB) - Good balance
- **Qwen2.5-Coder-7B-Instruct** (5GB) - Faster, smaller

See [MODELS.md](MODELS.md) for more details.

## OpenCode Integration

### About OpenCode

[OpenCode](https://opencode.ai) is an AI coding agent that works seamlessly with local-coder. It provides:
- Terminal UI (TUI) for interactive coding assistance
- Tool calling (read files, execute commands, modify code)
- Native support for local LLM providers
- Multi-file project understanding

### Installing OpenCode

```bash
# Quick install (recommended)
curl -fsSL https://opencode.ai/install | bash

# Using npm
npm install -g opencode-ai

# Using Homebrew
brew install anomalyco/tap/opencode
```

### Configure OpenCode

OpenCode stores configuration in `~/.config/opencode/opencode.json`.

local-coder uses **port 8081** by default. Your OpenCode config should include:

```json
{
  "apiBaseUrl": "http://127.0.0.1:8081/v1",
  "default_provider": "llama.cpp",
  "models": [
    {
      "id": "llama.cpp",
      "provider": "llama.cpp",
      "name": "Local llama.cpp Server"
    }
  ]
}
```

### Checking Your Configuration

```bash
# Check OpenCode config
cat ~/.config/opencode/opencode.json | jq .

# Verify it points to the right port
cat ~/.config/opencode/opencode.json | grep apiBaseUrl

# Check what port local-coder uses
local-coder config get .server.port
```

### Setting Up OpenCode (Step by Step)

1. **Install OpenCode** (if not already installed):
   ```bash
   curl -fsSL https://opencode.ai/install | bash
   ```

2. **Start the local-coder server:**
   ```bash
   local-coder start
   ```

3. **Launch OpenCode:**
   ```bash
   local-coder open
   ```

4. **In OpenCode TUI, verify connection:**
   - Press `/` to open command palette
   - Type `models` and press Enter
   - You should see your local model listed

5. **Start coding!**
   - Navigate to your project directory
   - Use `/help` to see available commands
   - Ask questions, request changes, generate code

### Alternative Launch Methods

```bash
# Method 1: Integrated command (recommended)
local-coder open

# Method 2: Direct launch with provider
opencode -m llama.cpp

# Method 3: Interactive provider selection
opencode
# Press Tab to switch to Build mode
# Type: /connect
# Select: llama.cpp
```

### Verifying the Connection

```bash
# 1. Check server is running
local-coder status

# 2. Test API endpoint
curl http://127.0.0.1:8081/v1/models

# 3. Check model is loaded
curl -s http://127.0.0.1:8081/v1/models | jq '.data[0].id'

# 4. Launch OpenCode
local-coder open
```

## Uninstallation

### Remove local-coder

```bash
# Remove binary
sudo rm /usr/local/bin/local-coder
# or: rm ~/.local/bin/local-coder

# Remove config and data (optional)
rm -rf ~/.config/local-coder
rm -rf ~/.local/share/local-coder
```

### Keep Models

Models are stored separately and won't be removed:
```
~/.cache/llama.cpp/         # llama.cpp cache
~/.local/share/local-coder/models/  # local-coder models
```

To remove models:
```bash
# List models first
local-coder models list

# Remove specific model
rm ~/.cache/llama.cpp/your-model.gguf

# Or remove all models (careful!)
rm ~/.cache/llama.cpp/*.gguf
```

## Troubleshooting Installation

### "command not found: local-coder"

**Cause:** local-coder not in PATH

**Solution:**
```bash
# Check if installed
which local-coder

# If in ~/.local/bin, add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### "jq: command not found"

**Cause:** jq JSON processor not installed

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install jq

# Arch Linux
sudo pacman -S jq

# Fedora
sudo dnf install jq
```

### "Permission denied" when installing

**Cause:** Need sudo to write to /usr/local/bin

**Solution:**
```bash
sudo ./scripts/install.sh

# Or use user installation method
```

### llama-server binary not found

**Cause:** llama.cpp not built or installed in different location

**Solution:**
```bash
# Build llama.cpp
cd ~/repos/llama.cpp
cmake -B build -DLLAMA_CUDA=ON
cmake --build build --config Release

# Update local-coder config if different path
local-coder config set .server.binary /path/to/llama-server
```

### Server starts but OpenCode can't connect

**Cause:** Port mismatch or firewall

**Solutions:**
```bash
# Check server is running
curl http://127.0.0.1:8081/v1/models

# Check OpenCode config
cat ~/.config/opencode/opencode.json | grep 8081

# Check if port is blocked
sudo ufw status
sudo firewall-cmd --list-all
```

## Next Steps

After installation:

1. [Configure for your GPU](README.md#gpu-optimization)
2. [Download your first model](README.md#model-commands)
3. [Start the server](README.md#usage)
4. [Launch OpenCode](README.md#quick-start)

For more information, see:
- [Main README](README.md)
- [Model Guide](MODELS.md)
- [llama.cpp Documentation](https://github.com/ggml-org/llama.cpp)
- [OpenCode Documentation](https://opencode.ai/docs)
