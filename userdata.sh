#! /bin/bash
echo "-------------------------------------"
echo "Upgrading python to 3.8 and installing ansible"
echo "-------------------------------------"
sudo yum update -y
sudo yum install python38 python38-virtualenv python38-pip -y
sudo pip-3.8 install --upgrade pip
pip3 install --user ansible
echo "-------------------------------------"
echo "Done"
echo "-------------------------------------"
