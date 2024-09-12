#!/bin/bash

# Metadata and Help Menu
show_help() {
  echo "
  Squid Proxy Installer Script for Ubuntu

  Usage:
    ./install_squid.sh --workstation <WORKSTATION_IPS> --domain <DOMAIN>

  Flags:
    --workstation    Specify one or more IP addresses (comma-separated) of workstations to allow HTTPS traffic.
    --domain         Specify the domain to allow HTTPS traffic from all workstations within that domain.

  Example:
    ./install_squid.sh --workstation 192.168.1.100,192.168.1.101 --domain democloud.ai

  This script will:
    1. Update the system.
    2. Install Squid Proxy.
    3. Configure Squid to allow HTTPS traffic from the specified workstations or domain.
    4. Restart the Squid service.

  Note: You must run this script as root or with sudo privileges.
  "
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Use sudo."
  exit 1
fi

# Parse input flags
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --workstation)
      WORKSTATION_IPS="$2"
      shift 2
      ;;
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Invalid option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

# If no flags provided, show help menu
if [[ -z "$WORKSTATION_IPS" && -z "$DOMAIN" ]]; then
  show_help
  exit 1
fi

# Check for mutual exclusivity
if [[ ! -z "$WORKSTATION_IPS" && ! -z "$DOMAIN" ]]; then
  echo "Error: You cannot use both --workstation and --domain flags together. Choose one."
  show_help
  exit 1
fi

# Main Script for Installing and Configuring Squid
echo "Starting the installation of Squid Proxy..."

# Update the system
echo "Updating the system..."
apt update && apt upgrade -y

# Install Squid
echo "Installing Squid..."
apt install squid -y

# Configure Squid
SQUID_CONF="/etc/squid/squid.conf"
echo "Configuring Squid..."

# Create a backup of the original squid.conf
cp $SQUID_CONF "${SQUID_CONF}.bak"

# Add ACL for workstations if provided
if [[ ! -z "$WORKSTATION_IPS" ]]; then
  IFS=',' read -r -a IP_ARRAY <<< "$WORKSTATION_IPS"
  for IP in "${IP_ARRAY[@]}"; do
    echo "acl allowed_workstation src $IP" >> $SQUID_CONF
    echo "http_access allow allowed_workstation" >> $SQUID_CONF
  done
fi

# Add ACL for domain if provided
if [[ ! -z "$DOMAIN" ]]; then
  echo "acl allowed_domain dstdomain $DOMAIN" >> $SQUID_CONF
  echo "http_access allow allowed_domain" >> $SQUID_CONF
fi

# Restart Squid to apply changes
echo "Restarting Squid service..."
systemctl restart squid

# Confirm Squid status
systemctl status squid --no-pager

echo "Squid installation and configuration completed."
if [[ ! -z "$WORKSTATION_IPS" ]]; then
  echo "HTTPS traffic from the specified workstations ($WORKSTATION_IPS) is now allowed through the proxy."
fi
if [[ ! -z "$DOMAIN" ]]; then
  echo "HTTPS traffic from all workstations within the domain ($DOMAIN) is now allowed through the proxy."
fi
