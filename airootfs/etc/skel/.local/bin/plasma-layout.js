/*
 * KDE Plasma Layout Script (Live System)
 * Rebuilds the desktop panel into a centered, floating bottom dock
 */

// 1. Remove all existing default panels
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) {
    allPanels[i].remove();
}

// 2. Create the floating dock panel at the bottom
var dock = new Panel();
dock.location = "bottom";
dock.height = 58;

// Center align the panel
dock.alignment = "center";

// Enable floating panel behavior (KDE Plasma 5.25+ & Plasma 6)
if ('floating' in dock) {
    dock.floating = true;
}

// Set dock length mode to only fit its content (creates the true floating dock widget)
if ('lengthMode' in dock) {
    dock.lengthMode = "Fit"; // Plasma 6
} else {
    // Plasma 5 fallback to simulate content-fitting
    dock.minimumLength = 100;
    dock.maximumLength = 1200;
}

// 3. Add Launcher Widget (App Menu button on the left)
var launcher = dock.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "system-search"); // Modern search/launcher icon

// 4. Add Icons-Only Task Manager (Pinned app shortcuts in the center)
var taskManager = dock.addWidget("org.kde.plasma.icontasks");
taskManager.currentConfigGroup = ["General"];
taskManager.writeConfig("launchers", [
    "applications:systemsettings.desktop",
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.kweather.desktop",
    "applications:spotify.desktop",
    "applications:firefox.desktop",
    "applications:org.kde.konsole.desktop"
]);

// 5. Add System Tray (For battery status, wifi status, volume control)
var tray = dock.addWidget("org.kde.plasma.systemtray");

// 6. Add Digital Clock (Styled precisely to HH:MM format without date)
var clock = dock.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showSeconds", "false");
clock.writeConfig("showDate", "false");
clock.writeConfig("use24hFormat", "true");
clock.writeConfig("timeFormat", "24h");
clock.writeConfig("customDateFormat", "HH:mm");
