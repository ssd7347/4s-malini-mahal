#!/bin/bash
set -e

TOMCAT_DIR="$HOME/tomcat"
WAR="backend/target/malinimahal.war"

# Build WAR
echo "==> Building backend..."
cd backend
mvn package -q -DskipTests
cd ..
echo "==> Build done."

# Kill any existing Tomcat process to avoid port conflicts on restart
pkill -f "catalina" 2>/dev/null || true
sleep 1

# Download Tomcat once (persists across restarts)
if [ ! -d "$TOMCAT_DIR" ]; then
  echo "==> Downloading Tomcat..."
  wget -q "https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.31/bin/apache-tomcat-10.1.31.tar.gz" -O /tmp/tc.tar.gz
  tar -xzf /tmp/tc.tar.gz -C "$HOME"
  mv "$HOME/apache-tomcat-10.1.31" "$TOMCAT_DIR"
  rm /tmp/tc.tar.gz
  rm -rf "$TOMCAT_DIR/webapps/"*
  echo "==> Tomcat ready."
fi

# Deploy latest WAR
cp "$WAR" "$TOMCAT_DIR/webapps/malinimahal.war"

echo "==> Starting Tomcat on port 8080..."
exec "$TOMCAT_DIR/bin/catalina.sh" run
