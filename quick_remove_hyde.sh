#!/bin/bash

# Quick Hyde Cleanup Script
# Removes the most common Hyde packages and configurations

echo "Quick Hyde (HyprV4) Cleanup"
echo "==========================="
echo

# Check if running Hyprland
if pgrep -x "Hyprland" > /dev/null; then
    echo "WARNING: Hyprland is currently running!"
    echo "It's recommended to switch to a different session before running this script."
    read -p "Continue anyway? (y/n): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to remove if installed
remove_if_installed() {
    local pkg="$1"
    if pacman -Qi "$pkg" &>/dev/null; then
        echo "Removing $pkg..."
        sudo pacman -Rns "$pkg" --noconfirm
    fi
}

echo "Creating backup of important configs..."
backup_dir="$HOME/hyde_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# Backup important configs
for dir in ".config/hypr" ".config/waybar" ".config/rofi" ".config/HyDE"; do
    if [ -d "$HOME/$dir" ]; then
        cp -r "$HOME/$dir" "$backup_dir/" 2>/dev/null || true
    fi
done

echo "Backup created at: $backup_dir"
echo

echo "Removing Hyde configurations..."
rm -rf "$HOME/.config/HyDE" 2>/dev/null || true
rm -rf "$HOME/.cache/HyDE" 2>/dev/null || true
rm -rf "$HOME/HyDE" 2>/dev/null || true

echo "Removing core Hyde packages..."

# Core Hyprland ecosystem
remove_if_installed "hyprland"
remove_if_installed "hyprpaper"
remove_if_installed "hyprpicker" 
remove_if_installed "hypridle"
remove_if_installed "hyprlock"
remove_if_installed "xdg-desktop-portal-hyprland"

# Status bars and launchers
remove_if_installed "waybar"
remove_if_installed "eww-wayland"
remove_if_installed "rofi-wayland"
remove_if_installed "wofi"

# Wallpaper and theming
remove_if_installed "swww"
remove_if_installed "hyprpaper"

# Notifications
remove_if_installed "dunst"
remove_if_installed "mako"

# Common Hyde utilities
remove_if_installed "wlogout"
remove_if_installed "cliphist"

echo
echo "Removing orphaned packages..."
sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || echo "No orphaned packages found"

echo
echo "Cleaning package cache..."
sudo pacman -Sc --noconfirm

echo
echo "Hyde cleanup completed!"
echo "Backup location: $backup_dir"
echo
echo "You may want to:"
echo "1. Reboot your system"
echo "2. Install a different desktop environment"
echo "3. Remove any remaining config directories manually if needed"
