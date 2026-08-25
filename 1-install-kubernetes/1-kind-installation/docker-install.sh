```bash
#!/bin/bash

# ============================================================
# Docker Installation Script
# ============================================================
#
# Docker is a tool that lets us run applications inside
# small, isolated environments called containers.
#
# This script will:
#
# 1. Update the system
# 2. Install Docker
# 3. Make Docker start automatically when the computer starts
# 4. Start Docker now
# 5. Allow the current user to run Docker without sudo
# 6. Check that Docker is working
#
# Before running this script, make sure:
#
# - You are using Ubuntu or another Debian-based Linux system
# - You have sudo permission
# - Your computer is connected to the internet
#
# IMPORTANT:
#
# After this script finishes, log out and log in again.
# This is required before Docker can be used without sudo.
#
# You can also run:
#
#     newgrp docker
#
# ============================================================

# Stop the script immediately if any command fails.
set -e

echo "============================================================"
echo "Docker installation is starting..."
echo "============================================================"

# ------------------------------------------------------------
# Step 1: Update the system
# ------------------------------------------------------------
#
# First, we ask Ubuntu to check for the latest package
# information and install available updates.
#
# Think of this as refreshing and updating the system
# before installing a new program.

echo ""
echo "[1/6] Updating the system..."

sudo apt update
sudo apt upgrade -y

# ------------------------------------------------------------
# Step 2: Install Docker
# ------------------------------------------------------------
#
# This command downloads and installs Docker.
#
# The -y option automatically answers "yes" when Ubuntu
# asks for confirmation.

echo ""
echo "[2/6] Installing Docker..."

sudo apt install docker.io -y

# ------------------------------------------------------------
# Step 3: Enable Docker at startup
# ------------------------------------------------------------
#
# This tells Ubuntu to start Docker automatically every time
# the computer starts.

echo ""
echo "[3/6] Setting Docker to start automatically..."

sudo systemctl enable docker

# ------------------------------------------------------------
# Step 4: Start Docker now
# ------------------------------------------------------------
#
# Enabling Docker affects future restarts.
# This command starts Docker immediately, without requiring
# you to restart the computer.

echo ""
echo "[4/6] Starting Docker..."

sudo systemctl start docker

# ------------------------------------------------------------
# Step 5: Allow the current user to use Docker
# ------------------------------------------------------------
#
# By default, Docker may require sudo.
#
# The following command adds the current user to the "docker"
# group. After logging out and logging in again, the user can
# normally run Docker commands without writing sudo each time.

echo ""
echo "[5/6] Giving the current user permission to use Docker..."

sudo usermod -aG docker "$USER"

echo "User '$USER' has been added to the docker group."

# ------------------------------------------------------------
# Step 6: Check the installation
# ------------------------------------------------------------
#
# First, show the installed Docker version.
# Then, check whether the Docker service is running.

echo ""
echo "[6/6] Checking the Docker installation..."

docker --version

echo ""
echo "Checking whether Docker is running..."

sudo systemctl is-active --quiet docker

echo "Docker is running correctly."

# ------------------------------------------------------------
# Installation complete
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Docker installation completed successfully!"
echo "============================================================"

echo ""
echo "One final step is required:"
echo ""
echo "Log out and log in again before using Docker without sudo."
echo ""
echo "You can also apply the change immediately by running:"
echo ""
echo "    newgrp docker"
echo ""
echo "After that, test Docker with:"
echo ""
echo "    docker ps"
echo ""
```
