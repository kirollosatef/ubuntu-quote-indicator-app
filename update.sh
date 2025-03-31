#!/bin/bash

# Exit on error
set -e

echo "Updating Quote Indicator..."

# Stop the running instance if it exists
pkill -f "python3 /usr/local/bin/quote-indicator" || true

# Copy the main script and icon
echo "Updating the application..."
sudo cp quote-indicator.py /usr/local/bin/quote-indicator
sudo chmod +x /usr/local/bin/quote-indicator

# Update the icon if it exists
if [ -f "quotes.png" ]; then
    sudo mkdir -p /usr/local/share/quote-indicator
    sudo cp quotes.png /usr/local/share/quote-indicator/
    # Update the desktop file to use the custom icon
    sed -i 's|Icon=format-text-quote-symbolic|Icon=/usr/local/share/quote-indicator/quotes.png|g' quote-indicator.desktop
fi

# Copy the desktop file
cp quote-indicator.desktop ~/.config/autostart/
cp quote-indicator.desktop ~/.local/share/applications/

echo "Update completed successfully!"
echo "You can restart the app by running 'quote-indicator' in a terminal or finding it in your applications menu."