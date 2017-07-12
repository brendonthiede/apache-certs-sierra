#!/bin/bash
set -e

sudo openssl req -new -sha256 -nodes -out /etc/apache2/ssl/localhost.csr -newkey rsa:2048 -keyout /etc/apache2/ssl/localhost.key -config openssl-san.cfg -reqexts req_ext
sudo openssl x509 -req -signkey /etc/apache2/ssl/localhost.key -in /etc/apache2/ssl/localhost.csr -req -days 3650 -out /etc/apache2/ssl/localhost.crt -extfile openssl-san.cfg -extensions req_ext
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /etc/apache2/ssl/localhost.crt
sudo apachectl graceful
