# Model Guide for local-coder

This guide covers recommended models for coding assistance with local-coder.

## Quick Recommendations

| Use Case | Model | Size | VRAM | Speed |
|----------|-------|------|------|-------|
| **Best Overall** | Qwen3-Coder-30B | 18GB | 16GB | Medium |
| **Balanced** | DeepSeek-Coder-v2 | 4-7GB | 12GB | Fast |
| **Fast** | Qwen2.5-Coder-7B | 5GB | 8GB | Very Fast |
| **Large Context** | DeepSeek-R1-Distill | 7-14GB | 12-16GB | Medium |

## Top Models for Coding

### 1. Qwen3-Coder-30B-A3B-Instruct (Recommended)

**Best for:** Serious development work, complex code generation

| Attribute | Value |
|-----------|-------|
| Parameters | 30B (A3B architecture) |
| File Size | ~18 GB (Q4_K_M) |
| Context Length | 262K tokens |
| VRAM Required | 16GB (with optimized settings) |
| Prompt Speed | ~900 t/s |
| Generation Speed | ~15 t/s |

**Why it's great:**
- Excellent code understanding and generation
- Large context window for big codebases
- Strong reasoning capabilities
- Good at multi-file projects

**Download:**
```bash
local-coder models download https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf
```

**Optimized settings for 16GB GPU:**
```bash
local-coder config set .server.gpu_layers 38
local-coder config set .server.n_cpu_moe 11
local-coder config set .server.ctx_size 16384
```

### 2. DeepSeek-Coder-v2-Instruct

**Best for:** Balanced performance and speed

| Attribute | Value |
|-----------|-------|
| Parameters | 16B |
| File Size | ~10 GB (Q4_K_M) |
| Context Length | 32K tokens |
| VRAM Required | 12GB |
| Prompt Speed | ~1100 t/s |
| Generation Speed | ~18 t/s |

**Why it's great:**
- Fast inference
- Good code quality
- Efficient memory usage
- Strong at following instructions

**Download:**
```bash
local-coder models download https://huggingface.co/mudler/DeepSeek-Coder-v2-Instruct-GGUF/resolve/main/DeepSeek-Coder-v2-Instruct.Q4_K_M.gguf
```

**Recommended settings:**
```bash
local-coder start --gpu-layers 35 --ctx-size 16384
```

### 3. Qwen2.5-Coder-7B-Instruct

**Best for:** Quick assistance, smaller GPUs

| Attribute | Value |
|-----------|-------|
| Parameters | 7B |
| File Size | ~5 GB (Q4_K_M) |
| Context Length | 32K tokens |
| VRAM Required | 8GB |
| Prompt Speed | ~1500 t/s |
| Generation Speed | ~25 t/s |

**Why it's great:**
- Very fast inference
- Low memory requirements
- Good for simple tasks
- Great for laptops

**Download:**
```bash
local-coder models download https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf
```

**Recommended settings:**
```bash
local-coder start --gpu-layers 28 --ctx-size 32768
```

### 4. DeepSeek-R1-Distill-Qwen-7B

**Best for:** Complex reasoning, debugging

| Attribute | Value |
|-----------|-------|
| Parameters | 7B (distilled) |
| File Size | ~5-9 GB |
| Context Length | 32K tokens |
| VRAM Required | 8-12GB |
| Speed | Fast |

**Why it's great:**
- Strong reasoning capabilities
- Good at explaining code
- Helpful for debugging
- Think-through approach

**Download:**
```bash
local-coder models download https://huggingface.co/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B.Q4_K_M.gguf
```

## Model Comparison

### Performance by Task

| Model | Code Gen | Debugging | Explanation | Speed |
|--------|----------|-----------|-------------|-------|
| Qwen3-Coder-30B | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| DeepSeek-Coder-v2 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Qwen2.5-Coder-7B | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| DeepSeek-R1-7B | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

### Memory Requirements

| Model | 8GB GPU | 12GB GPU | 16GB GPU | 24GB GPU |
|-------|---------|----------|----------|----------|
| Qwen2.5-Coder-7B | ✅ Optimal | ✅ | ✅ | ✅ |
| DeepSeek-R1-7B | ✅ Good | ✅ Optimal | ✅ | ✅ |
| DeepSeek-Coder-v2 | ❌ | ✅ Good | ✅ Optimal | ✅ |
| Qwen3-Coder-30B | ❌ | ❌ | ✅ Good | ✅ Optimal |

## Quantization Guide

GGUF models come in different quantization levels. Lower quality = smaller file.

### Q4_K_M (Recommended)

- **Size:** Medium (4-bit, medium)
- **Quality:** Good
- **Speed:** Fast
- **VRAM:** Balanced
- **Best for:** General use

### Q5_K_M

- **Size:** Large (5-bit, medium)
- **Quality:** Very Good
- **Speed:** Medium
- **VRAM:** Higher
- **Best for:** Quality-critical tasks

### Q3_K_M

- **Size:** Small (3-bit, medium)
- **Quality:** Fair
- **Speed:** Very Fast
- **VRAM:** Lower
- **Best for:** Resource-constrained systems

### Q8_0

- **Size:** Very Large (8-bit)
- **Quality:** Excellent
- **Speed:** Slower
- **VRAM:** Highest
- **Best for:** Maximum quality

**Recommendation:** Use Q4_K_M for best balance. Only switch if you have specific needs.

## Downloading Models

### From HuggingFace

```bash
# Direct download
local-coder models download https://huggingface.co/.../model.gguf

# Search for models
# Visit: https://huggingface.co/models?search=gguf
```

### Popular Model Repositories

| Repository | Description |
|------------|-------------|
| [Qwen](https://huggingface.co/Qwen) | Official Qwen models |
| [unsloth](https://huggingface.co/unsloth) | Optimized GGUF conversions |
| [mudler](https://huggingface.co/mudler) | High-quality quantizations |
| [TheBloke](https://huggingface.co/TheBloke) | Large model library |

### Finding Model URLs

1. Go to https://huggingface.co
2. Search for your model (e.g., "Qwen3 Coder GGUF")
3. Click on "Files and versions"
4. Find the `.gguf` file you want
5. Click "↓" to download
6. Copy the download link
7. Use with `local-coder models download <url>`

## Model Management

### List Models

```bash
local-coder models list
```

### Set Default Model

```bash
# Set by name
local-coder models set-default qwen3-coder

# Start with default
local-coder start
```

### Switch Models

```bash
# Start with specific model
local-coder start deepseek-coder

# Or by partial name match
local-coder start qwen2
```

### Delete Models

```bash
# List first
local-coder models list

# Delete by name
local-coder models delete old-model

# Or manually
rm ~/.cache/llama.cpp/model.gguf
```

## Context Size Selection

Different models support different context sizes. Larger context = more code fits in memory.

### Recommended Context Sizes

| GPU | Qwen3-30B | DeepSeek | Qwen2.5-7B |
|-----|-----------|----------|------------|
| 8GB | 4K | 8K | 16K |
| 12GB | 16K | 16K | 32K |
| **16GB** | **32K** ⭐ | 32K | 32K |
| 24GB | 32K | 32K | 32K |

**Note:** For RTX 5060 Ti (16GB), the **32K context** configuration is recommended as the optimal balance:
- **32K context**: 35 GPU layers = 97% utilization, 2.2 GB KV cache
- **16K context**: 38 GPU layers = 96% utilization, 1.2 GB KV cache
- **64K context**: 24 GPU layers = 77% utilization, 4.8 GB KV cache

The 32K configuration provides the best balance of GPU performance and context size for most coding tasks.

### When to Use Larger Context

- Analyzing entire files
- Multi-file refactoring
- Large codebase navigation
- Long conversations with extensive context

### When to Use Smaller Context

- Maximum inference speed
- Very large model on limited GPU
- Single-file operations
- Shorter coding sessions

### Trade-offs

Larger context uses more GPU memory for KV cache:
- 8K context: ~600 MB KV cache
- 16K context: ~1.2 GB KV cache
- **32K context: ~2.2 GB KV cache** ⭐
- 64K context: ~4.8 GB KV cache

**Key insight:** With 32K context on 16GB GPU, you still get 97% GPU utilization (35 layers) - the best of both worlds!

If you increase context size, you may need to reduce `--gpu-layers` to fit in GPU memory.

## Model-Specific Tips

### Qwen3-Coder-30B

```bash
# Recommended: 32K context with optimal GPU utilization (default config)
local-coder start

# Or explicitly:
local-coder start --ctx-size 32768 --gpu-layers 35 --n-cpu-moe 12

# For maximum performance (16K context)
local-coder start --ctx-size 16384 --gpu-layers 38 --n-cpu-moe 11

# For very large codebases (64K context, lower GPU utilization)
local-coder start --ctx-size 65536 --gpu-layers 24 --n-cpu-moe 20
```

### DeepSeek Models

```bash
# Standard models (no MoE)
local-coder start --n-cpu-moe 0

# Faster generation
local-coder start --ctx-size 8192
```

### Small Models (<10B)

```bash
# Can fit entirely on GPU
local-coder start --gpu-layers 99 --n-cpu-moe 0

# Maximize context
local-coder start --ctx-size 32768
```

## Troubleshooting Models

### Model Loading Errors

**"File not found"**
```bash
# Check model exists
local-coder models list

# Verify path
ls -la ~/.cache/llama.cpp/
```

**"Invalid GGUF format"**
```bash
# Verify file type
file ~/.cache/llama.cpp/*.gguf

# Re-download if corrupted
rm broken-model.gguf
local-coder models download <url>
```

### Performance Issues

**Slow inference:**
```bash
# Check GPU utilization
nvidia-smi

# Increase GPU layers
local-coder start --gpu-layers 40

# Reduce context size
local-coder start --ctx-size 8192
```

**Out of memory:**
```bash
# Reduce GPU layers
local-coder start --gpu-layers 30

# Increase n-cpu-moe for MoE models
local-coder start --n-cpu-moe 15

# Use smaller model
local-coder start qwen2-coder
```

## Using Models with OpenCode

OpenCode is an AI coding agent that works seamlessly with local-coder and your local models.

### Quick Start with OpenCode

```bash
# 1. Start the server
local-coder start

# 2. Launch OpenCode
local-coder open

# 3. Start coding!
# In OpenCode, ask questions, request changes, generate code
```

### OpenCode Commands for Model Work

In OpenCode TUI, use these commands:

- `/models` - See available models
- `/help` - Show all commands
- `/include <dir>` - Focus on specific directories
- `/exclude <dir>` - Exclude directories (node_modules, build, etc.)

### Example OpenCode Workflows

**Analyze a codebase:**
```
You are in: /path/to/project

Analyze this codebase and explain the architecture. Focus on:
1. Overall structure
2. Key components
3. Data flow
4. Entry points
```

**Multi-file refactoring:**
```
Refactor the authentication system:
1. Read @src/auth/login.ts
2. Read @src/auth/middleware.ts
3. Extract common validation logic into a shared utility
4. Update both files to use the new utility
5. Create tests for the new utility
```

**Code generation with context:**
```
Create a REST API endpoint for user management:
- GET /users - list all users
- GET /users/:id - get specific user
- POST /users - create new user
- PUT /users/:id - update user
- DELETE /users/:id - delete user

Use the existing patterns in @src/api/*.ts
```

### Optimizing OpenCode Performance

With the **32K context window**, you can work with large codebases effectively:

**For large projects:**
```
/include src
/exclude node_modules
/exclude dist
/exclude build
```

**For focused work:**
```
/include src/components
/exclude tests
```

**For understanding dependencies:**
```
Read @package.json
Analyze the dependency tree and identify any outdated or vulnerable packages.
```

### OpenCode + local-coder Tips

1. **Start with the optimal config:**
   ```bash
   local-coder start  # Uses 32K context by default
   ```

2. **Use the full context window:**
   - The 32K context lets you include entire files
   - Ask OpenCode to "read @src/" to include directory contents
   - Use multi-file prompts for complex tasks

3. **Leverage tool calling:**
   - OpenCode can read files, run commands, and modify code
   - Let it execute tests, linters, and formatters
   - Perfect for iterative development

4. **Monitor GPU usage:**
   ```bash
   # In another terminal
   watch -n 1 nvidia-smi
   ```

5. **Context management:**
   - Use `/reset` to clear conversation context
   - Use `/undo` to revert changes
   - Use `/redo` to apply reverted changes

## Updating Models

GGUF models get updated periodically. To update:

```bash
# Download new version
local-coder models download <new-url>

# Old model still exists - remove manually
local-coder models delete old-version
```

## Additional Resources

- [llama.cpp Model Compatibility](https://github.com/ggml-org/llama.cpp#model-compatibility)
- [HuggingFace GGUF Models](https://huggingface.co/models?search=gguf)
- [GGUF Quantization Guide](https://github.com/ggml-org/llama.cpp/pull/1685)
- [OpenCode Documentation](https://opencode.ai/docs)
