#!/bin/sh

# GPS Kiosk Startup Script - Auto-pull Volume config from GitHub

CONFIG_DIR="/home/node/.signalk"
GITHUB_REPO="https://github.com/Uncruise/gps-kiosk.git"
BRANCH="main"

echo "🚀 Starting GPS Kiosk..."
echo "📁 Config directory: $CONFIG_DIR"

# Always try to get latest configuration from GitHub
echo "📦 Updating configuration from GitHub..."

# If config directory is empty or doesn't exist, pull from GitHub
if [ -z "$(ls -A $CONFIG_DIR 2>/dev/null)" ]; then
  echo "📦 Volume is empty — pulling default config from GitHub..."
  
  # Clone the repository to temp location
  if command -v git >/dev/null 2>&1; then
    echo "🔄 Using Git to pull latest configuration..."
    git clone -b $BRANCH $GITHUB_REPO /tmp/config
    
    # Copy Volume contents to config directory
    if [ -d "/tmp/config/Volume" ]; then
      cp -a /tmp/config/Volume/* "$CONFIG_DIR/"
      echo "✅ Configuration copied from GitHub"
    else
      echo "⚠️  No Volume directory found in repository"
    fi
    
    # Clean up
    rm -rf /tmp/config
  else
    echo "⚠️  Git not available, using default configuration"
  fi
else
  echo "📋 Configuration exists, keeping current settings"
  echo "💡 To force update: delete volume contents and restart container"
fi

# Ensure proper permissions
chown -R node:node "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

echo "🌟 Starting Signal K Server..."
exec /usr/local/bin/signalk-server
