#!/bin/bash

# HP OMEN RGB Color Setup Script
# This script sets up RGB keyboard colors on startup/login
# Run this script automatically at login or manually when colors reset

# Configuration - Edit these values to customize your colors
DEFAULT_COLOR="0000FF"  # Blue - change this to your preferred default color
ZONE_COLORS=(
    "FF0000"    # Zone 0: Red
    "00FF00"    # Zone 1: Green  
    "0000FF"    # Zone 2: Blue
    "FFFF00"    # Zone 3: Yellow
)

# Alternatively, set all zones to the same color by uncommenting this:
# ZONE_COLORS=("$DEFAULT_COLOR" "$DEFAULT_COLOR" "$DEFAULT_COLOR" "$DEFAULT_COLOR")

# Path to the RGB zones
RGB_PATH="/sys/devices/platform/hp-wmi/rgb_zones"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to wait for hp-wmi module to be ready
wait_for_module() {
    local max_attempts=30
    local attempt=0
    
    log_message "Waiting for hp-wmi module to be ready..."
    
    while [ $attempt -lt $max_attempts ]; do
        if [ -d "$RGB_PATH" ] && [ -w "$RGB_PATH/zone00" ]; then
            log_message "hp-wmi module is ready!"
            return 0
        fi
        
        log_message "Attempt $((attempt + 1))/$max_attempts: Module not ready, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_message "ERROR: hp-wmi module not ready after $max_attempts attempts"
    return 1
}

# Function to set RGB colors
set_rgb_colors() {
    log_message "Setting up RGB keyboard colors..."
    
    # Check if RGB path exists
    if [ ! -d "$RGB_PATH" ]; then
        log_message "ERROR: RGB path not found: $RGB_PATH"
        log_message "Make sure the hp-wmi module is loaded: sudo modprobe hp_wmi"
        return 1
    fi
    
    # Set colors for each zone
    for i in {0..3}; do
        local zone_file="$RGB_PATH/zone0$i"
        local color="${ZONE_COLORS[$i]}"
        
        if [ -f "$zone_file" ]; then
            if echo "$color" | sudo tee "$zone_file" > /dev/null 2>&1; then
                log_message "Zone $i set to color: $color"
            else
                log_message "ERROR: Failed to set zone $i to color: $color"
                return 1
            fi
        else
            log_message "WARNING: Zone file not found: $zone_file"
        fi
    done
    
    log_message "RGB color setup completed successfully!"
    return 0
}

# Function to verify colors were set correctly
verify_colors() {
    log_message "Verifying RGB colors..."
    
    for i in {0..3}; do
        local zone_file="$RGB_PATH/zone0$i"
        if [ -f "$zone_file" ]; then
            local current_status=$(cat "$zone_file" 2>/dev/null | tr -d '\n')
            local expected_color="${ZONE_COLORS[$i]}"
            
            # Convert hex to decimal for comparison
            local expected_r=$((0x${expected_color:0:2}))
            local expected_g=$((0x${expected_color:2:2}))
            local expected_b=$((0x${expected_color:4:2}))
            local expected_format="red: $expected_r, green: $expected_g, blue: $expected_b"
            
            if [ "$current_status" = "$expected_format" ]; then
                log_message "Zone $i verified: $expected_color ($current_status) ✓"
            else
                log_message "Zone $i: expected $expected_color, current: $current_status"
            fi
        fi
    done
}

# Function to load hp-wmi module if not loaded
ensure_module_loaded() {
    if ! lsmod | grep -q "hp_wmi"; then
        log_message "hp-wmi module not loaded, attempting to load..."
        if sudo modprobe hp_wmi; then
            log_message "hp-wmi module loaded successfully"
            sleep 3  # Give it time to initialize
        else
            log_message "ERROR: Failed to load hp-wmi module"
            return 1
        fi
    else
        log_message "hp-wmi module is already loaded"
    fi
    return 0
}

# Function to show help
show_help() {
    cat << EOF
HP OMEN RGB Color Setup Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -c, --color COLOR   Set all zones to the same color (hex format: RRGGBB)
    -w, --wait          Wait for module to be ready before setting colors
    -v, --verify        Verify colors after setting them
    -q, --quiet         Suppress log messages (except errors)

EXAMPLES:
    $0                  # Set default rainbow colors
    $0 -c 0000FF        # Set all zones to blue
    $0 -w -v            # Wait for module and verify colors
    $0 --color FF0000   # Set all zones to red

CONFIGURATION:
Edit the ZONE_COLORS array in this script to customize your default colors.

AUTOMATIC STARTUP:
To run this script automatically at login, add it to your desktop environment's
autostart or create a systemd user service.
EOF
}

# Parse command line arguments
WAIT_FOR_MODULE=false
VERIFY_COLORS=false
QUIET=false
SINGLE_COLOR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--color)
            SINGLE_COLOR="$2"
            shift 2
            ;;
        -w|--wait)
            WAIT_FOR_MODULE=true
            shift
            ;;
        -v|--verify)
            VERIFY_COLORS=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Override log_message if quiet mode is enabled
if [ "$QUIET" = true ]; then
    log_message() {
        if [[ "$1" == ERROR* ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
        fi
    }
fi

# If single color is specified, set all zones to that color
if [ -n "$SINGLE_COLOR" ]; then
    ZONE_COLORS=("$SINGLE_COLOR" "$SINGLE_COLOR" "$SINGLE_COLOR" "$SINGLE_COLOR")
    log_message "Using single color for all zones: $SINGLE_COLOR"
fi

# Main execution
main() {
    log_message "Starting HP OMEN RGB color setup..."
    
    # Ensure module is loaded
    if ! ensure_module_loaded; then
        exit 1
    fi
    
    # Wait for module if requested
    if [ "$WAIT_FOR_MODULE" = true ]; then
        if ! wait_for_module; then
            exit 1
        fi
    fi
    
    # Set the colors
    if ! set_rgb_colors; then
        exit 1
    fi
    
    # Verify colors if requested
    if [ "$VERIFY_COLORS" = true ]; then
        verify_colors
    fi
    
    log_message "RGB color setup script completed!"
}

# Run main function
main "$@"
