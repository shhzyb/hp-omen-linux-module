#!/bin/bash

# Hyde (HyprV4) Cleanup Script
# This script removes Hyde/HyprV4 configuration and associated packages

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to ask for confirmation
ask_confirmation() {
    local prompt="$1"
    local response
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Backup function
create_backup() {
    local backup_dir="$HOME/hyde_backup_$(date +%Y%m%d_%H%M%S)"
    print_status "Creating backup directory: $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup important config directories
    for dir in ".config/hypr" ".config/waybar" ".config/rofi" ".config/dunst" ".config/kitty" ".config/swww"; do
        if [ -d "$HOME/$dir" ]; then
            print_status "Backing up $HOME/$dir"
            cp -r "$HOME/$dir" "$backup_dir/" 2>/dev/null || true
        fi
    done
    
    # Backup Hyde-specific directories
    if [ -d "$HOME/.config/HyDE" ]; then
        print_status "Backing up Hyde configuration"
        cp -r "$HOME/.config/HyDE" "$backup_dir/" 2>/dev/null || true
    fi
    
    print_success "Backup created at: $backup_dir"
    echo "$backup_dir" > "$HOME/.hyde_backup_location"
}

# Function to remove Hyde configuration files
remove_hyde_configs() {
    print_status "Removing Hyde configuration files..."
    
    # Hyde-specific directories
    local hyde_dirs=(
        "$HOME/.config/HyDE"
        "$HOME/.cache/HyDE"
        "$HOME/.local/share/HyDE"
        "$HOME/HyDE"
        "$HOME/.hyde"
    )
    
    for dir in "${hyde_dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_status "Removing $dir"
            rm -rf "$dir"
        fi
    done
    
    # Hyde-modified config directories (will ask for confirmation)
    local config_dirs=(
        "$HOME/.config/hypr"
        "$HOME/.config/waybar" 
        "$HOME/.config/rofi"
        "$HOME/.config/dunst"
        "$HOME/.config/swww"
        "$HOME/.config/kitty"
        "$HOME/.config/wlogout"
        "$HOME/.config/sddm"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [ -d "$dir" ]; then
            if ask_confirmation "Remove $dir (Hyde-modified config)?"; then
                print_status "Removing $dir"
                rm -rf "$dir"
            else
                print_warning "Skipping $dir"
            fi
        fi
    done
}

# Function to get list of Hyde-related packages
get_hyde_packages() {
    # Common packages installed by Hyde/HyprV4
    cat << 'EOF'
# Window Manager and Core
hyprland
xdg-desktop-portal-hyprland
hyprpaper
hyprpicker
hypridle
hyprlock

# Status Bar and System
waybar
eww-wayland

# Application Launcher and Menus
rofi-wayland
wofi

# Notifications
dunst
mako

# Terminal and Shell
kitty
fish
starship

# File Manager
thunar
thunar-volman
thunar-archive-plugin
thunar-media-tags-plugin

# Media and Graphics
swww
imagemagick
ffmpeg
grim
slurp
wl-clipboard
cliphist

# Audio
pipewire
pipewire-pulse
pipewire-alsa
pavucontrol
pamixer

# Fonts and Themes
ttf-fira-code
ttf-jetbrains-mono
ttf-font-awesome
noto-fonts-emoji
papirus-icon-theme
archcraft-gtk-theme-adapta
lxappearance

# System Tools
polkit-gnome
xorg-xrandr
brightnessctl
playerctl
bluez
bluez-utils
network-manager-applet

# Development and Utilities
git
wget
curl
unzip
zip
tree
neofetch
btop
htop

# Python and Scripting
python
python-pip
python-pillow
python-psutil

# Additional Hyde Components
wlogout
sddm
qt5-graphicaleffects
qt5-quickcontrols2
qt5-svg

# Wallpaper and Theming
nitrogen
feh
variety
EOF
}

# Function to remove packages
remove_packages() {
    print_status "Preparing to remove Hyde-related packages..."
    
    # Get package list
    local packages=($(get_hyde_packages | grep -v '^#' | grep -v '^$'))
    
    if [ ${#packages[@]} -eq 0 ]; then
        print_warning "No packages found to remove"
        return
    fi
    
    echo "The following packages will be removed:"
    printf '%s\n' "${packages[@]}" | column -c 80
    echo
    
    if ask_confirmation "Do you want to remove these packages?"; then
        # Filter out packages that are actually installed
        local installed_packages=()
        for pkg in "${packages[@]}"; do
            if pacman -Qi "$pkg" &>/dev/null; then
                installed_packages+=("$pkg")
            fi
        done
        
        if [ ${#installed_packages[@]} -gt 0 ]; then
            print_status "Removing installed packages..."
            sudo pacman -Rns "${installed_packages[@]}" --noconfirm
            print_success "Packages removed successfully"
        else
            print_warning "No Hyde packages found to remove"
        fi
    else
        print_warning "Package removal skipped"
    fi
}

# Function to clean up systemd services
cleanup_services() {
    print_status "Cleaning up systemd services..."
    
    # Stop and disable Hyde-related services
    local services=(
        "sddm.service"
        "bluetooth.service"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            if ask_confirmation "Disable $service?"; then
                sudo systemctl disable "$service"
                print_status "Disabled $service"
            fi
        fi
    done
}

# Function to clean up environment variables
cleanup_environment() {
    print_status "Cleaning up environment variables..."
    
    # Files that might contain Hyde-specific environment variables
    local env_files=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.profile"
        "$HOME/.xprofile"
        "$HOME/.pam_environment"
    )
    
    for file in "${env_files[@]}"; do
        if [ -f "$file" ]; then
            # Create backup
            cp "$file" "$file.hyde_backup"
            
            # Remove Hyde-specific lines (common patterns)
            sed -i '/HyDE/d' "$file"
            sed -i '/HYPR/d' "$file"
            sed -i '/waybar/d' "$file"
            sed -i '/swww/d' "$file"
            
            print_status "Cleaned $file (backup: $file.hyde_backup)"
        fi
    done
}

# Function to remove user-added repositories
cleanup_repositories() {
    print_status "Checking for custom repositories..."
    
    # Check for AUR helper
    if command -v yay &> /dev/null; then
        if ask_confirmation "Remove yay AUR helper?"; then
            sudo pacman -Rns yay --noconfirm
            print_status "Removed yay"
        fi
    fi
    
    if command -v paru &> /dev/null; then
        if ask_confirmation "Remove paru AUR helper?"; then
            sudo pacman -Rns paru --noconfirm
            print_status "Removed paru"
        fi
    fi
}

# Function to clean package cache and orphans
cleanup_system() {
    print_status "Cleaning up system..."
    
    # Remove orphaned packages
    if ask_confirmation "Remove orphaned packages?"; then
        sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || print_warning "No orphaned packages found"
    fi
    
    # Clean package cache
    if ask_confirmation "Clean package cache?"; then
        sudo pacman -Sc --noconfirm
        print_status "Package cache cleaned"
    fi
    
    # Clear user cache
    if ask_confirmation "Clear user cache directories?"; then
        rm -rf "$HOME/.cache/*" 2>/dev/null || true
        print_status "User cache cleared"
    fi
}

# Main execution
main() {
    echo "=============================================="
    echo "    Hyde (HyprV4) Cleanup Script"
    echo "=============================================="
    echo
    print_warning "This script will remove Hyde/HyprV4 and associated packages."
    print_warning "Make sure you have backups of any important configurations!"
    echo
    
    if ! ask_confirmation "Do you want to continue?"; then
        print_error "Cleanup cancelled by user"
        exit 1
    fi
    
    echo
    print_status "Starting Hyde cleanup process..."
    
    # Create backup
    if ask_confirmation "Create backup of configurations?"; then
        create_backup
    fi
    
    # Remove configurations
    if ask_confirmation "Remove Hyde configuration files?"; then
        remove_hyde_configs
    fi
    
    # Remove packages
    if ask_confirmation "Remove Hyde-related packages?"; then
        remove_packages
    fi
    
    # Cleanup services
    cleanup_services
    
    # Cleanup environment
    if ask_confirmation "Clean environment variables?"; then
        cleanup_environment
    fi
    
    # Cleanup repositories
    cleanup_repositories
    
    # Final system cleanup
    cleanup_system
    
    echo
    print_success "Hyde cleanup completed!"
    echo
    print_status "What you might want to do next:"
    echo "1. Reboot your system"
    echo "2. Install a different desktop environment or window manager"
    echo "3. Restore any backed-up configurations you want to keep"
    echo
    if [ -f "$HOME/.hyde_backup_location" ]; then
        local backup_location=$(cat "$HOME/.hyde_backup_location")
        print_status "Your backup is located at: $backup_location"
    fi
}

# Run main function
main "$@"
