#!/bin/bash
set -euo pipefail

# ================================================================================
# Desktop Icon Provisioning Script (System-Wide Defaults)
# ================================================================================
# Description:
#   Creates trusted symlinks for selected applications inside /etc/skel/Desktop.
#   These symlinks ensure that all newly created users receive desktop icons
#   without the "untrusted application launcher" warning dialog in Budgie.
#
# Notes:
#   - Designed for Budgie on Ubuntu 24.04 (X11).
#   - Budgie uses Nautilus-based desktop handling via budgie-desktop-view.
#   - Only affects *new* users created after this script runs.
#   - Symlinks preserve launcher trust metadata.
# ================================================================================

# ================================================================================
# Configuration: Applications to appear on every new user's desktop
# ================================================================================
APPS=(
  /usr/share/applications/google-chrome.desktop
  /usr/share/applications/firefox.desktop
  /usr/share/applications/code.desktop
  /usr/share/applications/postman.desktop
  /usr/share/applications/onlyoffice-desktopeditors.desktop
  /usr/share/applications/org.gnome.Terminal.desktop
)

SKEL_DESKTOP="/etc/skel/Desktop"

# ================================================================================
# Step 1: Ensure the skeleton Desktop directory exists
# ================================================================================
echo "NOTE: Ensuring /etc/skel/Desktop exists..."
mkdir -p "$SKEL_DESKTOP"

# ================================================================================
# Step 2: Create trusted symlinks for all selected applications
# ================================================================================
echo "NOTE: Creating trusted desktop files in /etc/skel/Desktop..."

for src in "${APPS[@]}"; do
  if [[ -f "$src" ]]; then
    filename=$(basename "$src")
    cp "$src" "$SKEL_DESKTOP/$filename"
    chmod +x "$SKEL_DESKTOP/$filename"
    sed -i '1s|^|#!/usr/bin/env xdg-open\n|' "$SKEL_DESKTOP/$filename"
    echo "NOTE: Added $filename (copied) to /etc/skel/Desktop"
  else
    echo "WARNING: $src not found, skipping"
  fi
done

echo "NOTE: New Budgie users will receive these desktop icons without prompts."

# ================================================================================
# Step 3: Disable apport crash reporting (desktop image hygiene)
# ================================================================================
sudo sed -i 's/enabled=1/enabled=0/' /etc/default/apport
sudo systemctl disable --now apport.service

# ==============================================================================
# Step 4: Disable animations for XRDP stability (system-wide + locked)
# ==============================================================================
echo "NOTE: Disabling Budgie animations via dconf (system-wide, locked)..."

# ------------------------------------------------------------------------------
# Dconf profile: local system database (safe to create if not present)
# ------------------------------------------------------------------------------
sudo mkdir -p /etc/dconf/profile
sudo tee /etc/dconf/profile/user >/dev/null <<'EOF'
user-db:user
system-db:local
EOF

# ------------------------------------------------------------------------------
# System-wide defaults
# ------------------------------------------------------------------------------
sudo mkdir -p /etc/dconf/db/local.d
sudo tee /etc/dconf/db/local.d/00-disable-animations >/dev/null <<'EOF'
[org/gnome/desktop/interface]
enable-animations=false
EOF

# ------------------------------------------------------------------------------
# Locks (prevent users from changing the value)
# ------------------------------------------------------------------------------
sudo mkdir -p /etc/dconf/db/local.d/locks
sudo tee /etc/dconf/db/local.d/locks/disable-animations >/dev/null <<'EOF'
/org/gnome/desktop/interface/enable-animations
EOF

# ------------------------------------------------------------------------------
# Compile dconf databases
# ------------------------------------------------------------------------------
sudo dconf update


echo "NOTE: Provisioning complete."
