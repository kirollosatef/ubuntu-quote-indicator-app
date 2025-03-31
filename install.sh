#!/bin/bash

# Exit on error
set -e

echo "Installing Quote Indicator..."

# Check for dependencies
echo "Checking dependencies..."
if ! command -v python3 &>/dev/null; then
  echo "Python 3 is required. Please install it first."
  exit 1
fi

# Install required packages
echo "Installing required packages..."
sudo apt-get update
sudo apt-get install -y python3-gi python3-notify2 gir1.2-appindicator3-0.1 gir1.2-gtk-3.0

# Create directories if they don't exist
mkdir -p ~/.local/share/quote-indicator
mkdir -p ~/.config/autostart

# Copy the main script
echo "Installing the application..."
sudo cp quote-indicator.py /usr/local/bin/quote-indicator
sudo chmod +x /usr/local/bin/quote-indicator

# Copy the desktop file
cp quote-indicator.desktop ~/.config/autostart/
cp quote-indicator.desktop ~/.local/share/applications/

echo "Installation completed successfully!"
echo "You can start the app from your applications menu or run 'quote-indicator' in a terminal."
echo "The app will also start automatically when you log in."
