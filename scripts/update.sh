#!/usr/bin/env bash

echo "=========== Updating ==========="
echo "Started at "$(date)
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get clean
sudo apt-get autoremove -y

if [ -f /var/run/reboot-required ]; # reboot if needed
then
    echo "System will restart"
    echo "Ending at "$(date)
    echo "========== Update Done =========="
    echo ""
    sudo reboot
else
    echo "Ending at "$(date)
    echo "========== Update Done =========="
    echo ""
fi
