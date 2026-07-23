#!/usr/bin/env bash

# This script runs automatically inside the live desktop environment
# on first boot. It configures the wallpaper, floating dock panel,
# theme settings, and Rofi keyboard shortcuts.

# Prevent the script from running more than once
LOCKFILE=~/.config/first-boot-setup.done
if [ -f "$LOCKFILE" ]; then
    exit 0
fi

# Display a desktop notification indicating setup has begun
kdialog --title "Custom OS Setup" --passivepopup "Configuring your glassmorphic KDE Plasma desktop... Please wait." 10

# Create wallpaper directory
mkdir -p ~/Pictures/Wallpapers

# Download the premium abstract blue gradient wallpaper
WALLPAPER_URL="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=2560&auto=format&fit=crop"
wget -q --show-progress -O ~/Pictures/Wallpapers/glassmorphic_blue.jpg "$WALLPAPER_URL"

# Apply the wallpaper to all virtual desktops
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var allDesktops = desktops();
    for (var i = 0; i < allDesktops.length; i++) {
        var d = allDesktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
        d.writeConfig('Image', 'file:///home/liveuser/Pictures/Wallpapers/glassmorphic_blue.jpg');
    }
"

# Set up global keyboard shortcuts for Rofi (Meta + Space)
kwriteconfig5 --file ~/.config/kglobalshortcutsrc --group "org.freedesktop.Breeze" --key "_launch_rofi" "Meta+Space,none,Launch Rofi"

# Map single-tap of the Windows/Super key to trigger Meta+Space (which starts Rofi)
kwriteconfig5 --file ~/.config/kwinrc --group "ModifierOnlyShortcuts" --key "Meta" "org.kde.keyboard,org.kde.keyboard,triggerShortcut,Meta+Space"

# Apply Fluent Dark Global look-and-feel theme
if command -v lookandfeeltool &> /dev/null; then
    lookandfeeltool -a org.kde.fluent-dark.desktop || true
fi

# Reload KWin shortcut config
qdbus org.kde.KWin /KWin reconfigure || true

# Execute the plasma scripting panel builder to create the floating bottom dock
if [ -f ~/.local/bin/plasma-layout.js ]; then
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat ~/.local/bin/plasma-layout.js)"
fi

# Mark setup as completed
touch "$LOCKFILE"

# Show success pop-up
kdialog --title "Custom OS Setup" --msgbox "Welcome! Your glassmorphic desktop environment has been successfully configured. Press the 'Windows' key to open the custom central launcher grid."
