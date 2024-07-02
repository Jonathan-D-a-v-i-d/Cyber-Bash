#!/bin/bash

# =============================================================================
# Script Name: InitiateDNS&Sniff.sh
# Description: This script sets up a DNS server using BIND and captures DNS
#              queries using tshark, with options to start and stop the services.
# Author:      Jon David
# Date:        YYYY-MM-DD
# Version:     1.0
# =============================================================================
# Parameters:
#   -Interface, --interface    : Network interface to listen on (mandatory for start action)
#   -PCap_Output, --pcap-output: Destination of the pcap file (default: ./dns_queries.pcap)
#   -Action, --action          : Action to perform (start or stop) (mandatory)
#   -h, --help                 : Display this help message
#
# Usage:
#   sudo ./InitiateDNS&Sniff.sh -Interface eth0 -PCap_Output /path/to/output.pcap -Action start
#   sudo ./InitiateDNS&Sniff.sh -Action stop
#
# Requirements:
#   - BIND (named)
#   - tshark
#
# Notes:
#   - Ensure you have the necessary permissions to install packages and start/stop services.
# =============================================================================

# Function to display help message
display_help() {
    cat << EOF
Usage: sudo ./InitiateDNS&Sniff.sh [OPTIONS]

Options:
  -Interface, --interface      Network interface to listen on (mandatory for start action)
  -PCap_Output, --pcap-output  Destination of the pcap file (default: ./dns_queries.pcap)
  -Action, --action            Action to perform (start or stop) (mandatory)
  -h, --help                   Display this help message

Examples:
  sudo ./InitiateDNS&Sniff.sh -Interface eth0 -PCap_Output /path/to/output.pcap -Action start
  sudo ./InitiateDNS&Sniff.sh -Action stop
EOF
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install BIND if not installed
install_bind() {
    if ! command_exists named; then
        echo "BIND (named) is not installed. Installing BIND..."
        sudo apt-get update
        sudo apt-get install -y bind9 bind9utils bind9-doc
    else
        echo "BIND (named) is already installed."
    fi
}

# Function to configure BIND
configure_bind() {
    BIND_CONF="/etc/bind/named.conf.options"

    if [ -f "$BIND_CONF" ]; then
        echo "BIND configuration file found."
    else
        echo "Creating BIND configuration file..."
        sudo bash -c 'cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";

    // Forwarders (DNS servers to forward queries to)
    forwarders {
        8.8.8.8; // Google DNS
        8.8.4.4; // Google DNS
    };

    // Enable DNSSEC validation
    dnssec-validation auto;

    // Listen on IPv4 and IPv6 addresses
    listen-on { any; };
    listen-on-v6 { any; };

    // Allow queries from any IP
    allow-query { any; };
};
EOF'
        echo "BIND configuration file created."
    fi
}

# Function to start BIND service
start_bind_service() {
    if systemctl list-unit-files | grep -q '^named.service'; then
        if ! sudo systemctl is-active --quiet named; then
            echo "Starting BIND service (named.service)..."
            sudo systemctl start named
            sudo systemctl enable named
            echo "BIND service started and enabled to run on boot."
        else
            echo "BIND service (named.service) is already running."
        fi
    else
        echo "BIND service not found. Please check if BIND (named) is installed correctly."
        exit 1
    fi
}

# Function to stop BIND service
stop_bind_service() {
    if systemctl list-unit-files | grep -q '^named.service'; then
        echo "Stopping BIND service (named.service)..."
        sudo systemctl stop named
        echo "BIND service stopped."
    else
        echo "BIND service not found. Please check if BIND (named) is installed correctly."
        exit 1
    fi
}

# Function to install tshark if not installed
install_tshark() {
    if ! command_exists tshark; then
        echo "tshark is not installed. Installing tshark..."
        sudo apt-get update
        sudo apt-get install -y tshark
    else
        echo "tshark is already installed."
    fi
}

# Function to start capturing DNS traffic
start_tshark() {
    local interface=$1
    local output_file=$2

    echo "Starting tshark to capture DNS traffic on interface $interface..."
    sudo tshark -i "$interface" -f "port 53" -w "$output_file" &
    TSHARK_PID=$!
    echo $TSHARK_PID > /var/run/tshark.pid
    echo "tshark is running with PID $TSHARK_PID. Capturing DNS queries to $output_file."
}

# Function to stop capturing DNS traffic
stop_tshark() {
    if [ -f /var/run/tshark.pid ]; then
        TSHARK_PID=$(cat /var/run/tshark.pid)
        echo "Stopping tshark with PID $TSHARK_PID..."
        sudo kill $TSHARK_PID
        rm /var/run/tshark.pid
        echo "tshark stopped."
    else
        echo "tshark PID file not found. Is tshark running?"
    fi
}

# Main function to initiate DNS server and sniff DNS queries
initiate_dns_and_sniff() {
    local interface=$1
    local output_file=$2

    install_bind
    configure_bind
    start_bind_service
    install_tshark
    start_tshark "$interface" "$output_file"
}

# Main function to stop DNS server and sniffing
stop_dns_and_sniff() {
    stop_tshark
    stop_bind_service
}

# Parse input parameters
INTERFACE=""
OUTPUT_FILE="./dns_queries.pcap"
ACTION=""

if [[ $# -eq 0 ]]; then
    display_help
    exit 1
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -Interface|--interface) INTERFACE="$2"; shift ;;
        -PCap_Output|--pcap-output) OUTPUT_FILE="$2"; shift ;;
        -Action|--action) ACTION="$2"; shift ;;
        -h|--help) display_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; display_help; exit 1 ;;
    esac
    shift
done

# Validate mandatory parameters for start action
if [ "$ACTION" == "start" ] && [ -z "$INTERFACE" ]; then
    echo "Error: -Interface is a mandatory parameter for the start action."
    display_help
    exit 1
fi

# Validate mandatory parameters
if [ -z "$ACTION" ]; then
    echo "Error: -Action is a mandatory parameter."
    display_help
    exit 1
fi

# Execute the appropriate action based on input parameters
if [ "$ACTION" == "start" ]; then
    initiate_dns_and_sniff "$INTERFACE" "$OUTPUT_FILE"
    echo "DNS server setup and DNS query sniffing initiated."
elif [ "$ACTION" == "stop" ]; then
    stop_dns_and_sniff
    echo "DNS server and DNS query sniffing stopped."
else
    echo "Unknown action: $ACTION. Use 'start' or 'stop'."
    display_help
    exit 1
fi
