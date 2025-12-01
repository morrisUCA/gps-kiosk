#!/bin/sh

# GPS Kiosk Startup Script - Auto-pull Volume config from GitHub

CONFIG_DIR="/home/node/.signalk"
GITHUB_REPO="https://github.com/Uncruise/gps-kiosk.git"
BRANCH="main"

echo "🚀 Starting GPS Kiosk..."
echo "📁 Config directory: $CONFIG_DIR"

# Always pull latest configuration from GitHub (overwriting existing settings)
echo "📦 Updating configuration from GitHub..."

# Always pull from GitHub to ensure latest settings
if command -v git >/dev/null 2>&1; then
  echo "🔄 Pulling latest configuration from GitHub..."
  
  # Clone the repository to temp location
  git clone -b $BRANCH $GITHUB_REPO /tmp/config
  
  # Backup existing config if it exists (for debugging)
  if [ -d "$CONFIG_DIR" ] && [ "$(ls -A $CONFIG_DIR 2>/dev/null)" ]; then
    echo "📋 Backing up existing configuration..."
    rm -rf /tmp/config-backup 2>/dev/null
    cp -a "$CONFIG_DIR" /tmp/config-backup
  fi
  
  # Clear existing configuration
  rm -rf "$CONFIG_DIR"/*
  
  # Copy Volume contents to config directory
  if [ -d "/tmp/config/Volume" ]; then
    cp -a /tmp/config/Volume/* "$CONFIG_DIR/"
    echo "✅ Latest configuration applied from GitHub"
    echo "🔄 All settings updated to match repository"
  else
    echo "⚠️  No Volume directory found in repository"
    # Restore backup if GitHub pull failed
    if [ -d "/tmp/config-backup" ]; then
      echo "🔙 Restoring previous configuration due to error"
      cp -a /tmp/config-backup/* "$CONFIG_DIR/"
    fi
  fi
  
  # Clean up
  rm -rf /tmp/config /tmp/config-backup
else
  echo "⚠️  Git not available - cannot update configuration"
  echo "📋 Using existing configuration"
fi

# Ensure proper permissions
chown -R node:node "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

echo "🌟 Starting Signal K Server..."
exec /usr/local/bin/signalk-server
