#!/bin/bash
set -euo pipefail

# ================================================================================
# Ubuntu 24.04 + Budgie Desktop Installation Script
# ================================================================================
# Description:
#   Installs the Budgie desktop environment on Ubuntu 24.04.
#
# Notes:
#   - Uses apt-get for stable automation behavior.
#   - Installs LightDM as the display manager (recommended for Budgie).
#   - Budgie is an X11 desktop (XRDP-friendly); no Wayland session is expected.
# ================================================================================
#

# ================================================================================
# Step 1: Install the Budgie desktop environment (meta package)
# ================================================================================
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ubuntu-budgie-desktop \
  lightdm

# ================================================================================
# Step 2: Ensure LightDM is the active display manager (noninteractive)
# ================================================================================
sudo sh -c 'echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections'
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure lightdm

# ================================================================================
# Step 3: Install common Budgie/desktop utilities (terminal, tools, XDG helpers)
# ================================================================================
sudo apt-get install -y \
  gnome-terminal \
  xdg-utils \
  dbus-x11

# ================================================================================
# Step 4: Remove LibreOffice since it doesn't work well with XRDP sessions
# ================================================================================

sudo apt purge -y libreoffice*
sudo apt autoremove -y

# ================================================================================
# Step 5: Remove software center and related package management tools
# ================================================================================

sudo apt purge -y \
  gnome-software-plugin-snap \
  gnome-software-plugin-flatpak \
  packagekit \
  fwupd
