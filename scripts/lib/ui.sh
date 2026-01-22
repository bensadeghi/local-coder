#!/usr/bin/env bash
# UI functions for local-coder

# Print info message
info() {
    echo -e "${COLOR_BLUE}ℹ${COLOR_RESET} $*"
}

# Print success message
success() {
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"
}

# Print warning message
warn() {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $*" >&2
}

# Print error message
error() {
    echo -e "${COLOR_RED}✗${COLOR_RESET} $*" >&2
}

# Print debug message (only if LOCAL_CODER_DEBUG is set)
debug() {
    if [[ -n "$LOCAL_CODER_DEBUG" ]]; then
        echo -e "${COLOR_CYAN}[debug]${COLOR_RESET} $*" >&2
    fi
}

# Print a header
header() {
    echo -e "${COLOR_BOLD}$*${COLOR_RESET}"
}

# Print a section divider
divider() {
    echo -e "${COLOR_BOLD}${1:-───}${COLOR_RESET}"
}

# Print a key-value pair
kv() {
    local key="$1"
    local value="$2"
    printf "  ${COLOR_CYAN}%s${COLOR_RESET}: %s\n" "$key" "$value"
}

# Confirm action (returns 0 for yes, 1 for no)
confirm() {
    local prompt="$1"
    local default="${2:-n}"

    local yn
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]"
    else
        prompt="$prompt [y/N]"
    fi

    read -rp "$prompt " yn
    yn=${yn:-$default}

    case "$yn" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# Show a spinner (for long operations)
spinner_start() {
    local msg="$1"
    local pid_file="$PID_DIR/spinner.$$"

    # Create a named pipe for communication
    local fifo
    fifo=$(mktemp -u)
    mkfifo "$fifo"
    exec 3<>"$fifo"
    rm -f "$fifo"

    # Start spinner in background
    (
        local spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        while true; do
            i=$(( (i + 1) % 10 ))
            printf "\r${COLOR_CYAN}%s${COLOR_RESET} %s" "${spin:$i:1}" "$msg"
            sleep 0.1
        done
    ) &
    local spin_pid=$!
    echo $spin_pid > "$pid_file"

    # Cleanup function
    trap "kill $spin_pid 2>/dev/null; rm -f '$pid_file' 2>/dev/null; printf '\r'" RETURN
}

# Stop the spinner
spinner_stop() {
    local result_msg="${1:-done}"
    local pid_file="$PID_DIR/spinner.$$"

    if [[ -f "$pid_file" ]]; then
        local spin_pid
        spin_pid=$(cat "$pid_file")
        kill "$spin_pid" 2>/dev/null || true
        rm -f "$pid_file"
    fi

    printf "\r${COLOR_GREEN}✓${COLOR_RESET} %s\n" "$result_msg"
}

# Show progress bar (for downloads, etc.)
progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local label="${4:-}"

    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))

    printf "\r%s [" "$label"
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

# Format bytes to human-readable
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")

    local unit=0
    local size=$bytes

    while (( size > 1024 && unit < 4 )); do
        size=$((size / 1024))
        unit=$((unit + 1))
    done

    if [[ $unit -eq 0 ]]; then
        echo "${size} ${units[$unit]}"
    else
        printf "%.1f %s\n" "$(echo "$bytes / 1024^$unit" | bc -l)" "${units[$unit]}"
    fi
}

# Format duration in seconds to human-readable
format_duration() {
    local seconds=$1

    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [[ $hours -gt 0 ]]; then
        printf "%dh %dm %ds\n" "$hours" "$minutes" "$secs"
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %ds\n" "$minutes" "$secs"
    else
        printf "%ds\n" "$secs"
    fi
}

# Show table
table_show() {
    local delimiter="${1:-|}"
    local header="$2"
    shift 2

    # Print header
    echo -e "${COLOR_BOLD}$header${COLOR_RESET}"
    divider

    # Print rows
    while [[ $# -gt 0 ]]; do
        echo "$1" | tr "$delimiter" "  "
        shift
    done
}

# Export functions
export -f info success warn error debug header divider kv
export -f confirm
export -f spinner_start spinner_stop
export -f progress_bar format_bytes format_duration table_show
