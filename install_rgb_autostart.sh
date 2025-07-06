#!/bin/bash

# HP OMEN RGB Auto-Setup Installer
# This script installs the RGB color setup script to run automatically at login

SCRIPT_DIR="/home/shaw/hp-omen-linux-module"
SCRIPT_NAME="setup_rgb_colors.sh"
SERVICE_NAME="hp-omen-rgb.service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "HP OMEN RGB Auto-Setup Installer"
echo "================================="

# Check if script exists
if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
    echo "ERROR: Script not found: $SCRIPT_DIR/$SCRIPT_NAME"
    exit 1
fi

# Check if service file exists
if [ ! -f "$SCRIPT_DIR/$SERVICE_NAME" ]; then
    echo "ERROR: Service file not found: $SCRIPT_DIR/$SERVICE_NAME"
    exit 1
fi

# Create systemd user directory if it doesn't exist
echo "Creating systemd user directory..."
mkdir -p "$SYSTEMD_USER_DIR"

# Copy service file to systemd user directory
echo "Installing systemd service..."
cp "$SCRIPT_DIR/$SERVICE_NAME" "$SYSTEMD_USER_DIR/"

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl --user daemon-reload

# Enable the service
echo "Enabling RGB setup service..."
systemctl --user enable hp-omen-rgb.service

echo ""
echo "Installation completed successfully!"
echo ""
echo "The RGB color setup script will now run automatically at login."
echo ""
echo "Manual commands:"
echo "  Start service now:    systemctl --user start hp-omen-rgb.service"
echo "  Check status:         systemctl --user status hp-omen-rgb.service"
echo "  View logs:            journalctl --user -u hp-omen-rgb.service"
echo "  Disable service:      systemctl --user disable hp-omen-rgb.service"
echo ""
echo "You can also run the script manually:"
echo "  $SCRIPT_DIR/$SCRIPT_NAME --help"
echo ""
echo "To test the service, you can restart it:"
echo "  systemctl --user restart hp-omen-rgb.service"
