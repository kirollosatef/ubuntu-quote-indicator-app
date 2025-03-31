#!/bin/bash

# Exit on error
set -e

echo "Updating Quote Indicator..."

# Stop the running instance if it exists
pkill -f "python3 /usr/local/bin/quote-indicator" || true

# Copy the main script
echo "Updating the application..."
sudo cp quote-indicator.py /usr/local/bin/quote-indicator
sudo chmod +x /usr/local/bin/quote-indicator

# Copy the desktop file
cp quote-indicator.desktop ~/.config/autostart/
cp quote-indicator.desktop ~/.local/share/applications/

echo "Update completed successfully!"
echo "You can restart the app by running 'quote-indicator' in a terminal or finding it in your applications menu."
