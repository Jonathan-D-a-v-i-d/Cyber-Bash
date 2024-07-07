#!/bin/bash

#################################################################
# Script Name    : Install&Enable_ApacheStruts2.sh
# Description    : This script installs Apache Struts 2 on a Tomcat server,
#                  starts and enables the Tomcat service, and provides
#                  options to start or stop the service.
# Args           : -Start (to install, start and enable Tomcat)
#                  -Stop (to stop the Tomcat service)
# Author         : [Your Name]
# Email          : [Your Email]
# Date           : [Today's Date]
# Examples       :
#                  1. To install Apache Struts 2, start and enable Tomcat:
#                     ./Install&Enable_ApacheStruts2.sh -Start
#
#                  2. To stop the Tomcat service:
#                     ./Install&Enable_ApacheStruts2.sh -Stop
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

# Check for arguments
if [ "$1" == "-Start" ]; then
  install_and_enable
elif [ "$1" == "-Stop" ]; then
  stop_service
else
  echo "Usage: $0 -Start | -Stop"
  echo "  -Start : Install Apache Struts 2 and start and enable Tomcat service"
  echo "  -Stop  : Stop the Tomcat service"
fi
