#!/bin/bash

# This script fixes the icon path in the installed application
# to use the custom icon (quotes.png) in the top panel

echo "Updating quote indicator to use custom icon..."

# Stop the running instance if it exists
pkill -f "python3 /usr/local/bin/quote-indicator" || true

# Create a modified version of the Python script
cat > /tmp/quote-indicator-modified.py << 'EOF'
#!/usr/bin/env python3
import gi
import json
import os
import random
import time
from threading import Thread
import notify2

gi.require_version('Gtk', '3.0')
gi.require_version('AppIndicator3', '0.1')
from gi.repository import Gtk, GLib, AppIndicator3 as AppIndicator

class QuoteIndicator:
    def __init__(self):
        self.app = 'quote-indicator'
        
        # Path to the custom icon
        icon_path = '/usr/local/share/quote-indicator/quotes.png'
        
        # Use absolute path for custom icon
        self.indicator = AppIndicator.Indicator.new(
            self.app,
            icon_path,
            AppIndicator.IndicatorCategory.APPLICATION_STATUS
        )
        
        self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        
        # Initialize notification system
        notify2.init(self.app)
        
        # Create data directory if it doesn't exist
        self.data_dir = os.path.expanduser('~/.local/share/quote-indicator')
        if not os.path.exists(self.data_dir):
            os.makedirs(self.data_dir)
        
        # Initialize quotes file
        self.quotes_file = os.path.join(self.data_dir, 'quotes.json')
        if not os.path.exists(self.quotes_file):
            with open(self.quotes_file, 'w') as f:
                json.dump([], f)
        
        # Initialize settings file
        self.settings_file = os.path.join(self.data_dir, 'settings.json')
        if not os.path.exists(self.settings_file):
            with open(self.settings_file, 'w') as f:
                json.dump({
                    'interval': 30,
                    'active': True
                }, f)
        
        # Load settings
        self.load_settings()
        
        # Setup menu
        self.setup_menu()
        
        # Start quote display thread
        self.quote_thread = Thread(target=self.quote_timer)
        self.quote_thread.daemon = True
        self.quote_thread.start()
    
    def load_settings(self):
        with open(self.settings_file, 'r') as f:
            settings = json.load(f)
        self.interval = settings.get('interval', 30)
        self.active = settings.get('active', True)
    
    def save_settings(self):
        settings = {
            'interval': self.interval,
            'active': self.active
        }
        with open(self.settings_file, 'w') as f:
            json.dump(settings, f)
    
    def load_quotes(self):
        with open(self.quotes_file, 'r') as f:
            return json.load(f)
    
    def save_quotes(self, quotes):
        with open(self.quotes_file, 'w') as f:
            json.dump(quotes, f)
    
    def setup_menu(self):
        menu = Gtk.Menu()
        
        # Add Quote item
        item_add_quote = Gtk.MenuItem(label='Add Quote')
        item_add_quote.connect('activate', self.add_quote)
        menu.append(item_add_quote)
        
        # Manage Quotes item
        item_manage_quotes = Gtk.MenuItem(label='Manage Quotes')
        item_manage_quotes.connect('activate', self.manage_quotes)
        menu.append(item_manage_quotes)
        
        # Set Interval item
        item_set_interval = Gtk.MenuItem(label=f'Set Interval ({self.interval} min)')
        item_set_interval.connect('activate', self.set_interval)
        menu.append(item_set_interval)
        
        # Toggle active state
        item_toggle = Gtk.CheckMenuItem(label='Quotes Active')
        item_toggle.set_active(self.active)
        item_toggle.connect('toggled', self.toggle_active)
        menu.append(item_toggle)
        self.item_toggle = item_toggle
        
        # Separator
        menu.append(Gtk.SeparatorMenuItem())
        
        # Show Random Quote Now
        item_show_quote = Gtk.MenuItem(label='Show Random Quote Now')
        item_show_quote.connect('activate', self.show_random_quote)
        menu.append(item_show_quote)
        
        # Separator
        menu.append(Gtk.SeparatorMenuItem())
        
        # Quit item
        item_quit = Gtk.MenuItem(label='Quit')
        item_quit.connect('activate', self.quit)
        menu.append(item_quit)
        
        menu.show_all()
        self.indicator.set_menu(menu)
        self.menu = menu
    
    def quote_timer(self):
        last_time = time.time()
        while True:
            time.sleep(1)
            if not self.active:
                last_time = time.time()
                continue
                
            current_time = time.time()
            if current_time - last_time >= self.interval * 60:
                GLib.idle_add(self.display_random_quote)
                last_time = current_time
    
    def display_random_quote(self):
        quotes = self.load_quotes()
        if not quotes:
            notification = notify2.Notification(
                "No Quotes Available",
                "Please add quotes to your collection."
            )
            notification.show()
            return
        
        quote = random.choice(quotes)
        
        # Only show author if it exists and isn't "Unknown"
        if quote['author'] and quote['author'] != 'Unknown':
            notification_text = f"\"{quote['text']}\"\n\n— {quote['author']}"
        else:
            notification_text = f"\"{quote['text']}\""
            
        notification = notify2.Notification(
            "Quote of the Moment",
            notification_text
        )
        notification.set_timeout(10000)  # 10 seconds
        notification.show()
    
    def show_random_quote(self, widget):
        self.display_random_quote()
    
    def add_quote(self, widget):
        dialog = Gtk.Dialog(
            title="Add New Quote",
            parent=None,
            flags=0
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OK, Gtk.ResponseType.OK
        )
        dialog.set_default_size(350, 200)
        
        box = dialog.get_content_area()
        
        label_text = Gtk.Label(label="Quote Text:")
        box.add(label_text)
        
        entry_text = Gtk.TextView()
        entry_text.set_wrap_mode(Gtk.WrapMode.WORD)
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_hexpand(True)
        scrolled.set_vexpand(True)
        scrolled.add(entry_text)
        box.add(scrolled)
        
        label_author = Gtk.Label(label="Author:")
        box.add(label_author)
        
        entry_author = Gtk.Entry()
        box.add(entry_author)
        
        box.show_all()
        
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            buffer = entry_text.get_buffer()
            text = buffer.get_text(
                buffer.get_start_iter(),
                buffer.get_end_iter(),
                True
            )
            author = entry_author.get_text()
            
            if text.strip():
                quotes = self.load_quotes()
                quotes.append({
                    'text': text.strip(),
                    'author': author.strip() or 'Unknown'
                })
                self.save_quotes(quotes)
        
        dialog.destroy()
    
    def manage_quotes(self, widget):
        quotes = self.load_quotes()
        
        dialog = Gtk.Dialog(
            title="Manage Quotes",
            parent=None,
            flags=0
        )
        dialog.add_buttons(
            Gtk.STOCK_CLOSE, Gtk.ResponseType.CLOSE
        )
        dialog.set_default_size(500, 400)
        
        box = dialog.get_content_area()
        
        # Create ListStore model
        liststore = Gtk.ListStore(str, str, int)  # text, author, index
        for i, quote in enumerate(quotes):
            liststore.append([quote['text'], quote['author'], i])
        
        # Create TreeView
        treeview = Gtk.TreeView(model=liststore)
        
        # Add columns
        renderer_text = Gtk.CellRendererText()
        renderer_text.set_property("wrap-width", 300)
        renderer_text.set_property("wrap-mode", Gtk.WrapMode.WORD)
        column_text = Gtk.TreeViewColumn("Quote", renderer_text, text=0)
        column_text.set_expand(True)
        treeview.append_column(column_text)
        
        renderer_author = Gtk.CellRendererText()
        column_author = Gtk.TreeViewColumn("Author", renderer_author, text=1)
        column_author.set_min_width(100)
        treeview.append_column(column_author)
        
        # Put the treeview in a ScrolledWindow
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_hexpand(True)
        scrolled.set_vexpand(True)
        scrolled.add(treeview)
        
        box.add(scrolled)
        
        # Buttons for actions
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        
        button_edit = Gtk.Button(label="Edit")
        button_edit.connect("clicked", self.edit_quote, treeview, liststore, quotes)
        button_box.pack_start(button_edit, True, True, 0)
        
        button_delete = Gtk.Button(label="Delete")
        button_delete.connect("clicked", self.delete_quote, treeview, liststore, quotes)
        button_box.pack_start(button_delete, True, True, 0)
        
        box.add(button_box)
        
        box.show_all()
        
        dialog.run()
        dialog.destroy()
    
    def edit_quote(self, button, treeview, liststore, quotes):
        selection = treeview.get_selection()
        model, iter_ = selection.get_selected()
        
        if iter_ is not None:
            text = model[iter_][0]
            author = model[iter_][1]
            index = model[iter_][2]
            
            dialog = Gtk.Dialog(
                title="Edit Quote",
                parent=None,
                flags=0
            )
            dialog.add_buttons(
                Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                Gtk.STOCK_OK, Gtk.ResponseType.OK
            )
            dialog.set_default_size(350, 200)
            
            box = dialog.get_content_area()
            
            label_text = Gtk.Label(label="Quote Text:")
            box.add(label_text)
            
            entry_text = Gtk.TextView()
            buffer = entry_text.get_buffer()
            buffer.set_text(text)
            entry_text.set_wrap_mode(Gtk.WrapMode.WORD)
            scrolled = Gtk.ScrolledWindow()
            scrolled.set_hexpand(True)
            scrolled.set_vexpand(True)
            scrolled.add(entry_text)
            box.add(scrolled)
            
            label_author = Gtk.Label(label="Author:")
            box.add(label_author)
            
            entry_author = Gtk.Entry()
            entry_author.set_text(author)
            box.add(entry_author)
            
            box.show_all()
            
            response = dialog.run()
            if response == Gtk.ResponseType.OK:
                buffer = entry_text.get_buffer()
                new_text = buffer.get_text(
                    buffer.get_start_iter(),
                    buffer.get_end_iter(),
                    True
                )
                new_author = entry_author.get_text()
                
                if new_text.strip():
                    quotes[index] = {
                        'text': new_text.strip(),
                        'author': new_author.strip() or 'Unknown'
                    }
                    self.save_quotes(quotes)
                    
                    # Update the list store
                    liststore[iter_][0] = new_text.strip()
                    liststore[iter_][1] = new_author.strip() or 'Unknown'
            
            dialog.destroy()
    
    def delete_quote(self, button, treeview, liststore, quotes):
        selection = treeview.get_selection()
        model, iter_ = selection.get_selected()
        
        if iter_ is not None:
            index = model[iter_][2]
            
            dialog = Gtk.MessageDialog(
                parent=None,
                flags=0,
                message_type=Gtk.MessageType.QUESTION,
                buttons=Gtk.ButtonsType.YES_NO,
                text="Are you sure you want to delete this quote?"
            )
            dialog.format_secondary_text(f"\"{model[iter_][0]}\" — {model[iter_][1]}")
            
            response = dialog.run()
            if response == Gtk.ResponseType.YES:
                # Remove from quotes list and save
                del quotes[index]
                self.save_quotes(quotes)
                
                # Remove from liststore
                liststore.remove(iter_)
                
                # Update indexes in the liststore
                for i, row in enumerate(liststore):
                    row[2] = i
            
            dialog.destroy()
    
    def set_interval(self, widget):
        dialog = Gtk.Dialog(
            title="Set Interval",
            parent=None,
            flags=0
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OK, Gtk.ResponseType.OK
        )
        
        box = dialog.get_content_area()
        
        label = Gtk.Label(label="Set interval in minutes:")
        box.add(label)
        
        adjustment = Gtk.Adjustment(value=self.interval, lower=1, upper=1440, step_increment=1)
        spin_button = Gtk.SpinButton()
        spin_button.set_adjustment(adjustment)
        box.add(spin_button)
        
        box.show_all()
        
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            self.interval = int(spin_button.get_value())
            self.save_settings()
            
            # Update menu item label
            for item in self.menu.get_children():
                if isinstance(item, Gtk.MenuItem) and item.get_label().startswith('Set Interval'):
                    item.set_label(f'Set Interval ({self.interval} min)')
                    break
        
        dialog.destroy()
    
    def toggle_active(self, widget):
        self.active = widget.get_active()
        self.save_settings()
    
    def quit(self, widget):
        Gtk.main_quit()

def main():
    indicator = QuoteIndicator()
    Gtk.main()

if __name__ == '__main__':
    main()
EOF

# Copy the icon to the system location
if [ -f "quotes.png" ]; then
    sudo mkdir -p /usr/local/share/quote-indicator
    sudo cp quotes.png /usr/local/share/quote-indicator/
else
    echo "Error: quotes.png not found in current directory!"
    exit 1
fi

# Copy the modified script to the system location
sudo cp /tmp/quote-indicator-modified.py /usr/local/bin/quote-indicator
sudo chmod +x /usr/local/bin/quote-indicator

# Update the desktop file to use the custom icon
cat > quote-indicator.desktop << EOF
[Desktop Entry]
Name=Quote Indicator
Comment=Display random quotes at regular intervals
Exec=/usr/local/bin/quote-indicator
Icon=/usr/local/share/quote-indicator/quotes.png
Terminal=false
Type=Application
Categories=Utility;
X-GNOME-Autostart-enabled=true
EOF

# Copy the updated desktop file
cp quote-indicator.desktop ~/.config/autostart/
cp quote-indicator.desktop ~/.local/share/applications/

echo "Custom icon successfully set up!"
echo "You can restart the app by running 'quote-indicator' in a terminal."