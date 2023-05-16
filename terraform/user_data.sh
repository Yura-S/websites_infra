#!/bin/bash
apt -y update
apt -y install apache2
sudo service httpd start
chkconfig httpd on
