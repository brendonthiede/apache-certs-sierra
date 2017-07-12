# apache-certs-sierra

This took _way_ more time than it should have, and I'm guessing there is some over engineering, but this documents what I did to finally
get a self-signed certificate working in Sierra without having Chrome complain.

## Setup OpenSSL Configuration

I created a configuration file at `/etc/apache2/openssl-san.cfg` with the following contents:

    [req]
    default_bits = 2048
    prompt = no
    default_md = sha256
    req_extensions = req_ext
    distinguished_name = dn
    
    [ dn ]
    C=US
    ST=Michigan
    L=East Lansing
    O=End Point
    OU=Testing Domain
    emailAddress=your-administrative-address@vertafore.com
    CN = localhost
    
    [ req_ext ]
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = localhost

## Create Certificate Signing Request

    sudo openssl req -new -sha256 -nodes -out /etc/apache2/ssl/localhost.csr -newkey rsa:2048 -keyout /etc/apache2/ssl/localhost.key -config openssl-san.cfg -reqexts req_ext

## Create Certificate Based on CSR

    sudo openssl x509 -req -signkey /etc/apache2/ssl/localhost.key -in /etc/apache2/ssl/localhost.csr -req -days 3650 -out /etc/apache2/ssl/localhost.crt -extfile openssl-san.cfg -extensions req_ext

## Trust the Certificate in the System Keychain

    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /etc/apache2/ssl/localhost.crt

## Enable Apache Modules and Extra Config

Edit the file `/etc/apache2/httpd.conf` to make the following changes:

### Set ServerName

    ServerName localhost

### Enable modules and configurations for Virtual Hosts, PHP, and SSL (uncomment `LoadModule` and `Include` lines)

    LoadModule vhost_alias_module libexec/apache2/mod_vhost_alias.so
    Include /private/etc/apache2/extra/httpd-vhosts.conf
    LoadModule php5_module libexec/apache2/libphp5.so
    LoadModule socache_shmcb_module libexec/apache2/mod_socache_shmcb.so
    LoadModule ssl_module libexec/apache2/mod_ssl.so
    Include /private/etc/apache2/extra/httpd-ssl.conf

## Edit SSL Configuration (`/etc/apache2/extra/httpd-ssl.conf`)

In the file `/etc/apache2/extra/httpd-ssl.conf` the values for `SSLCertificateFile` `SSLCertificateKeyFile` need to point to the
newly generated certificate and key:

    SSLCertificateFile "/etc/apache2/ssl/localhost.crt"
    SSLCertificateKeyFile "/etc/apache2/ssl/localhost.key"

## Configure SSL for Virtual Host (`/etc/apache2/extra/httpd-vhosts.conf`)

The file `/etc/apache2/extra/httpd-vhosts.conf` will need a `VirtualHost` section that tells it to use the generated certificate.
The follwoing is an example that also allows CORS and has a sample reverse proxy.

    <VirtualHost *:443>
        ServerName localhost
        DocumentRoot "/Library/WebServer/Documents"
    
        SSLEngine on
        SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL
        SSLCertificateFile /etc/apache2/ssl/localhost.crt
        SSLCertificateKeyFile /etc/apache2/ssl/localhost.key
    
        <Directory "/Library/WebServer/Documents">
            Options Indexes FollowSymLinks
            AllowOverride All
            Order allow,deny
            Allow from all
            Require all granted
        </Directory>
    
        # Allow CORS requests so that localhost can use remote servers, etc.
        <IfModule mod_headers.c>
           SetEnvIf Origin "http(s)?://(.+)$" ACAO=$0
           Header set Access-Control-Allow-Origin %{ACAO}e env=ACAO
        </IfModule>
        Header set Access-Control-Allow-Credentials "true"
        ProxyRequests Off
        ProxyPreserveHost On
        <Proxy *>
            Order deny,allow
            Allow from all
        </Proxy>
        # Proxy some service running locally on a different port (but on the same path)
        ProxyPass /awesomeapp http://localhost:8080/awesomeapp timeout=600
        ProxyPassReverse /awesomeapp http://localhost:8080/awesomeapp
    </VirtualHost>

## Restart Apache

    sudo apachectl graceful
