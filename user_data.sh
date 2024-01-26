#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
echo "Deploy a web server on aws" | sudo tee /var/www/html/index.html