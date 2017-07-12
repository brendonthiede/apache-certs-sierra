sudo openssl req -new -sha256 -nodes -out /etc/apache2/ssl/localhost.csr -newkey rsa:2048 -keyout /etc/apache2/ssl/localhost.key -config openssl-san.cfg -reqexts req_ext
sudo openssl x509 -req -signkey /etc/apache2/ssl/localhost.key -in /etc/apache2/ssl/localhost.csr -req -days 3650 -out /etc/apache2/ssl/localhost.crt -extfile openssl-san.cfg -extensions req_ext
#sudo openssl req -new -x509 -key /etc/apache2/ssl/localhost.key -out /etc/apache2/ssl/localhost.crt -days 3650 -subj /CN=localhost
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /etc/apache2/ssl/localhost.crt
sudo apachectl graceful
echo "[INFO] You should check other configuration for Sierra here: https://gist.github.com/jonathantneal/774e4b0b3d4d739cbc53"
echo "[INFO] Especially check out /etc/apache2/extra/httpd-vhosts.conf and /etc/apache2/extra/httpd-ssl.conf"
