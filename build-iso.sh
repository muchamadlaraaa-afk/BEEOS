#!/usr/bin/env bash

# Custom Linux ISO builder script (Archiso)
set -e

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root (sudo)."
    exit 1
fi

echo "=== BEEOS Custom ISO Builder ==="
echo ""

# 1. Update keyring and install build tools (including grub and mtools for UEFI ISO creation)
echo "[1/5] Updating keyring and installing archiso dependencies..."
pacman -Sy --noconfirm archlinux-keyring || true
pacman -Syu --noconfirm || true
pacman -S --noconfirm --needed archiso git wget curl squashfs-tools xorriso grub mtools dosfstools

# 2. Setup profile workspace
echo "[2/5] Setting up Archiso workspace..."
BUILD_DIR="/tmp/archiso-build"
WORK_DIR="/tmp/archiso-work"
OUT_DIR="/tmp/archiso-out"

rm -rf "$BUILD_DIR" "$WORK_DIR" "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

# Copy the official Arch Linux live profile (releng) template
cp -a /usr/share/archiso/configs/releng/. "$BUILD_DIR/"

# 3. Download & Inject Theme Assets directly into the ISO Root filesystem
echo "[3/5] Downloading and compiling glassmorphic themes & icon packs system-wide..."

mkdir -p "$BUILD_DIR/airootfs/usr/share/themes"
mkdir -p "$BUILD_DIR/airootfs/usr/share/icons"
mkdir -p "$BUILD_DIR/airootfs/usr/share/color-schemes"
mkdir -p "$BUILD_DIR/airootfs/usr/share/aurorae/themes"
mkdir -p "$BUILD_DIR/airootfs/usr/share/plasma/desktoptheme"
mkdir -p "$BUILD_DIR/airootfs/usr/share/plasma/look-and-feel"

# Clone Fluent KDE theme and run installer
echo "Fetching Fluent KDE theme packages..."
TEMP_THEME="/tmp/fluent-kde-src"
rm -rf "$TEMP_THEME"
git clone --depth 1 https://github.com/vinceliuice/Fluent-kde.git "$TEMP_THEME"
if [ -f "$TEMP_THEME/install.sh" ]; then
    chmod +x "$TEMP_THEME/install.sh"
    "$TEMP_THEME/install.sh" -d "$BUILD_DIR/airootfs/usr/share" || true
fi
rm -rf "$TEMP_THEME"

# Clone Fluent Icon theme and run installer
echo "Fetching Fluent squircle icon theme pack..."
TEMP_ICONS="/tmp/fluent-icons-src"
rm -rf "$TEMP_ICONS"
git clone --depth 1 https://github.com/vinceliuice/Fluent-icon-theme.git "$TEMP_ICONS"
if [ -f "$TEMP_ICONS/install.sh" ]; then
    chmod +x "$TEMP_ICONS/install.sh"
    "$TEMP_ICONS/install.sh" -d "$BUILD_DIR/airootfs/usr/share/icons" || true
fi
rm -rf "$TEMP_ICONS"

# 4. Copy custom configurations from our project
echo "[4/5] Copying custom overlay configs and profile settings..."
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

cp "$SCRIPT_DIR/profiledef.sh" "$BUILD_DIR/profiledef.sh"
cat "$SCRIPT_DIR/packages.x86_64" >> "$BUILD_DIR/packages.x86_64"

# Remove any duplicate package lines
sort -u "$BUILD_DIR/packages.x86_64" -o "$BUILD_DIR/packages.x86_64"

mkdir -p "$BUILD_DIR/airootfs/etc/sddm.conf.d"
mkdir -p "$BUILD_DIR/airootfs/etc/skel/.config/autostart"
mkdir -p "$BUILD_DIR/airootfs/etc/skel/.config/rofi"
mkdir -p "$BUILD_DIR/airootfs/etc/skel/.local/bin"

cp "$SCRIPT_DIR/airootfs/etc/sddm.conf.d/autologin.conf" "$BUILD_DIR/airootfs/etc/sddm.conf.d/autologin.conf"
cp "$SCRIPT_DIR/airootfs/etc/skel/.config/autostart/first-boot.desktop" "$BUILD_DIR/airootfs/etc/skel/.config/autostart/first-boot.desktop"
cp "$SCRIPT_DIR/airootfs/etc/skel/.config/rofi/config.rasi" "$BUILD_DIR/airootfs/etc/skel/.config/rofi/config.rasi"
cp "$SCRIPT_DIR/airootfs/etc/skel/.local/bin/first-boot-setup.sh" "$BUILD_DIR/airootfs/etc/skel/.local/bin/first-boot-setup.sh"
cp "$SCRIPT_DIR/airootfs/etc/skel/.local/bin/plasma-layout.js" "$BUILD_DIR/airootfs/etc/skel/.local/bin/plasma-layout.js"

chmod +x "$BUILD_DIR/airootfs/etc/skel/.local/bin/first-boot-setup.sh"

mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.service.d"
ln -sf /usr/lib/systemd/system/sddm.service "$BUILD_DIR/airootfs/etc/systemd/system/display-manager.service"
mkdir -p "$BUILD_DIR/airootfs/etc/systemd/system/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$BUILD_DIR/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service"

# 5. Compile the ISO using mkarchiso
echo "[5/5] Compiling bootable BEEOS ISO..."
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$BUILD_DIR"

echo ""
echo "=== BUILD COMPLETE ==="
echo "Your custom BEEOS bootable ISO is ready!"
echo "ISO Location: $OUT_DIR/"
echo "======================"
