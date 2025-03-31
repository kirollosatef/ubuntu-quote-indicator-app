## Ubuntu Quote Indicator App

I've created a professional indicator application for Ubuntu that will display random quotes at intervals you specify. The app creates an icon in the top panel that provides a menu to manage your quotes and settings.

### Features

* Add, edit, and delete quotes
* Set custom time intervals for displaying quotes (in minutes)
* Enable/disable quote notifications with a toggle
* Show a random quote on demand
* Automatic startup when you log in
* Persistent storage of quotes and settings

### Installation Instructions

1. Make the installation script executable:
   ```bash
   chmod +x install.sh
   ```
3. Run the installation script:
   ```bash
   ./install.sh
   ```

### Usage

Once installed, you'll see an indicator icon in your top panel. Click on it to access the following options:

* **Add Quote** : Add a new quote with author attribution
* **Manage Quotes** : View, edit, or delete your existing quotes
* **Set Interval** : Change how often random quotes are displayed
* **Quotes Active** : Toggle to enable/disable quote notifications
* **Show Random Quote Now** : Display a random quote immediately
* **Quit** : Exit the application

### Technical Notes

* The app uses GTK3 and AppIndicator3 for the GUI components
* Quote notifications use the system notification service
* Quotes and settings are stored in JSON files in `~/.local/share/quote-indicator/`
* The app runs as a background service with minimal resource usage
