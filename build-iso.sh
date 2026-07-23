#!/usr/bin/env bash

# Custom Linux ISO builder script (Archiso)
# This script must be run on an Arch Linux system or virtual machine.
# It sets up the default releng profile, applies customizations, compiles
# the glassmorphic themes/icons directly into the ISO filesystem, and builds it.

set -e

# Ensure the script is run with root permissions
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root (sudo)."
    exit 1
fi

echo "=== Glassmorphic Custom ISO Builder ==="
echo ""

# 1. Install Archiso package if not present
echo "[1/5] Installing archiso and compilation tools..."
pacman -Sy --noconfirm --needed archiso git wget curl squashfs-tools xorriso

# 2. Setup profile workspace
echo "[2/5] Setting up Archiso workspace..."
BUILD_DIR="/tmp/archiso-build"
WORK_DIR="/tmp/archiso-work"
OUT_DIR="/tmp/archiso-out"

# Clean up previous builds if they exist
rm -rf "$BUILD_DIR" "$WORK_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

# Copy the official Arch Linux live profile (releng) template
cp -r /usr/share/archiso/configs/releng/* "$BUILD_DIR"

# 3. Download & Inject Theme Assets directly into the ISO Root filesystem
echo "[3/5] Downloading and compiling glassmorphic themes & icon packs system-wide..."

# Create target directories in the ISO overlay
mkdir -p "$BUILD_DIR/airootfs/usr/share/themes"
mkdir -p "$BUILD_DIR/airootfs/usr/share/icons"
mkdir -p "$BUILD_DIR/airootfs/usr/share/color-schemes"
mkdir -p "$BUILD_DIR/airootfs/usr/share/aurorae/themes"
mkdir -p "$BUILD_DIR/airootfs/usr/share/plasma/desktoptheme"
mkdir -p "$BUILD_DIR/airootfs/usr/share/plasma/look-and-feel"

# Clone Fluent KDE theme and copy folders declaratively
echo "Fetching Fluent KDE theme packages..."
TEMP_THEME="/tmp/fluent-kde-src"
rm -rf "$TEMP_THEME"
git clone --depth 1 https://github.com/vinceliuice/Fluent-kde.git "$TEMP_THEME"

cp -r "$TEMP_THEME/look-and-feel/"* "$BUILD_DIR/airootfs/usr/share/plasma/look-and-feel/"
cp -r "$TEMP_THEME/plasma/desktoptheme/"* "$BUILD_DIR/airootfs/usr/share/plasma/desktoptheme/"
cp -r "$TEMP_THEME/color-schemes/"* "$BUILD_DIR/airootfs/usr/share/color-schemes/"
cp -r "$TEMP_THEME/aurorae/themes/"* "$BUILD_DIR/airootfs/usr/share/aurorae/themes/"
rm -rf "$TEMP_THEME"

# Clone Fluent Icon theme and copy folders declaratively
echo "Fetching Fluent squircle icon theme pack..."
TEMP_ICONS="/tmp/fluent-icons-src"
rm -rf "$TEMP_ICONS"
git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git "$TEMP_ICONS"

cp -r "$TEMP_ICONS/src/Fluent" "$BUILD_DIR/airootfs/usr/share/icons/"
cp -r "$TEMP_ICONS/src/Fluent-dark" "$BUILD_DIR/airootfs/usr/share/icons/"
rm -rf "$TEMP_ICONS"

# 4. Copy custom configurations from our project
echo "[4/5] Copying custom overlay configs and profile settings..."
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Copy package list and profile configuration
cp "$SCRIPT_DIR/profiledef.sh" "$BUILD_DIR/profiledef.sh"
cat "$SCRIPT_DIR/packages.x86_64" >> "$BUILD_DIR/packages.x86_64"

# Copy custom configurations (autostart, clock script, SDDM, rofi, layout)
mkdir -p "$BUILD_DIR/airootfs/etc/sddm.conf.d"
mkdir -p "$BUILD_DIR/airootfs/etc/skel/.config/autostart"
mkdir -p "$BUILD_DIR/airootfs/etc/skel/.config/rofi"
mkdir -p "$BUILD_DIR/airootfs/etc/skel/.local/bin"

cp "$SCRIPT_DIR/airootfs/etc/sddm.conf.d/autologin.conf" "$BUILD_DIR/airootfs/etc/sddm.conf.d/autologin.conf"
cp "$SCRIPT_DIR/airootfs/etc/skel/.config/autostart/first-boot.desktop" "$BUILD_DIR/airootfs/etc/skel/.config/autostart/first-boot.desktop"
cp "$SCRIPT_DIR/airootfs/etc/skel/.config/rofi/config.rasi" "$BUILD_DIR/airootfs/etc/skel/.config/rofi/config.rasi"
cp "$SCRIPT_DIR/airootfs/etc/skel/.local/bin/first-boot-setup.sh" "$BUILD_DIR/airootfs/etc/skel/.local/bin/first-boot-setup.sh"
cp "$SCRIPT_DIR/airootfs/etc/skel/.local/bin/plasma-layout.js" "$BUILD_DIR/airootfs/etc/skel/.local/bin/plasma-layout.js"

# Set permissions for executable scripts
chmod +x "$BUILD_DIR/airootfs/etc/skel/.local/bin/first-boot-setup.sh"

# Enable SDDM and NetworkManager inside the live system systemd services
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.service.d"
ln -sf /usr/lib/systemd/system/sddm.service "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.service"
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$BUILD_DIR/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service"

# 5. Compile the ISO using mkarchiso
echo "[5/5] Compiling bootable custom ISO..."
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$BUILD_DIR"

echo ""
echo "=== BUILD COMPLETE ==="
echo "Your custom bootable ISO is ready!"
echo "ISO Location: $OUT_DIR/archlinux-glassmorphic-kde-$(date +%Y.%m.%d)-x86_64.iso"
echo "You can burn this ISO to a USB flash drive or boot it directly inside a Virtual Machine."
echo "======================"
