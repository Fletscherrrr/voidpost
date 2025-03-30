#!/bin/bash

set -e

# Function to display dialog menu
drawDialog() {
    dialog --stdout "$@"
}

# Function to check for command failure
failureCheck() {
    if [ $? -ne 0 ]; then
        echo "Error encountered! Exiting..."
        exit 1
    fi
}

# Updating system and setting up repositories
echo "Updating system and enabling additional repositories..."
xbps-install -Syu xbps
xbps-install -Sy void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree
xbps-install -Syu || failureCheck

# Installing necessary packages
echo "Installing essential packages..."
xbps-install -Sy dialog pipewire wireplumber flatpak dosfstools base-devel wget ncurses libgcc xdg-desktop-portal xdg-utils xdg-user-dirs \
    bash dbus elogind bash-completion file tldr less man-pages mdocml pciutils usbutils dhcpcd chrony \
    kbd iproute2 iputils ethtool kmod acpid eudev lvm2 networkmanager libgcc-32bit libstdc++-32bit libdrm-32bit libglvnd-32bit mono vulkan-loader vulkan-loader-32bit wine winetricks google-fonts-ttf freefont-ttf || failureCheck

# Flatpak setup
echo "Adding Flathub Repo"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Enable and configure PipeWire system-wide
echo "Configuring PipeWire system-wide..."
mkdir -p /etc/pipewire/pipewire.conf.d
ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
ln -s /usr/share/applications/pipewire.desktop /etc/xdg/autostart/

# CPU Microcode Selection
cpuChoice=$(drawDialog --no-cancel --title "Desktop Environment" --extra-button --extra-label "Map" --menu "" 0 0 0 "intel" "" "amd" "" "skip" "")

# GPU Driver Selection
graphicsChoice=$(drawDialog --no-cancel --title "Desktop Environment" --extra-button --extra-label "Map" --menu "" 0 0 0 "intel" "" "amd" "" "nvidia" "" "nvidia-optimus" "" "skip" "")

# Desktop Environment Selection
desktopChoice=$(drawDialog --no-cancel --title "Desktop Environment" --extra-button --extra-label "Map" --menu "" 0 0 0 "kde" "" "gnome" "" "budgie" "" "cinnamon" "" "awesomewm" "" "i3" "" "qtile" "" "skip" "")

# Install Selected CPU Microcode
case $cpuChoice in
    intel)
        echo "Installing Intel CPU microcode..."
        xbps-install -Sy intel-ucode || failureCheck
        ;;
    amd)
        echo "Installing AMD CPU microcode..."
        xbps-install -Sy linux-firmware-amd || failureCheck
        ;;
    skip)
        echo "Skipping CPU microcode installation..."
        ;;
esac

# Install Selected GPU Drivers
case $graphicsChoice in
    amd)
        echo "Installing AMD graphics drivers..."
        xbps-install -Sy mesa-dri mesa-dri-32bit vulkan-loader mesa-vulkan-radeon mesa-vaapi mesa-vdpau || failureCheck
        ;;
    nvidia)
        echo "Installing NVIDIA graphics drivers..."
        xbps-install -Sy nvidia-dkms nvidia-libs nvidia-libs-32bit linux-firmware-nvidia || failureCheck
        ;;
    intel)
        echo "Installing Intel graphics drivers..."
        xbps-install -Sy mesa-dri mesa-dri-32bit vulkan-loader mesa-vulkan-intel intel-video-accel || failureCheck
        ;;
    nvidia-optimus)
        echo "Installing Intel and NVIDIA graphics drivers..."
        xbps-install -Sy nvidia-dkms nvidia-libs nvidia-libs-32bit linux-firmware-nvidia mesa-dri vulkan-loader mesa-vulkan-intel intel-video-accel || failureCheck
        ;;
    skip)
        echo "Skipping graphics driver installation..."
        ;;
esac

# Install Selected Desktop Environment
case $desktopChoice in
    kde)
        echo "Installing KDE Plasma..."
        xbps-install -Sy kde-plasma sddm || failureCheck
        ln -s /etc/sv/sddm /var/service/
        ;;
    gnome)
        echo "Installing GNOME..."
        xbps-install -Sy gnome gnome-tweaks gdm || failureCheck
        ln -s /etc/sv/gdm /var/service/
        ;;
    budgie)
        echo "Installing Budgie..."
        xbps-install -Sy budgie-desktop lightdm || failureCheck
        ln -s /etc/sv/lightdm /var/service/
        ;;
    cinnamon)
        echo "Installing Cinnamon..."
        xbps-install -Sy cinnamon lightdm || failureCheck
        ln -s /etc/sv/lightdm /var/service/
        ;;
    awesomewm)
        echo "Installing AwesomeWM..."
        xbps-install -Sy awesome || failureCheck
        ;;
    i3)
        echo "Installing i3 Gaps..."
        xbps-install -Sy i3-gaps || failureCheck
        ;;
    qtile)
        echo "Installing Qtile..."
        xbps-install -Sy qtile || failureCheck
        ;;
    skip)
        echo "Skipping desktop environment installation..."
        ;;
esac

# Enable relevant services
echo "Enabling necessary services..."
ln -s /etc/sv/{dbus,elogind,acpid,chronyd,NetworkManager} /var/service/

# Completion message
echo "Post-installation script completed successfully."
