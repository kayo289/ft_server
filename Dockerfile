FROM debian:buster

#install tool, delete apt cash
RUN	apt-get update && apt-get upgrade -y \
 && apt-get install -y nginx wget curl vim supervisor openssl \
				   mariadb-server mariadb-client \
				   php-cgi php-common php7.3-fpm php-pear php-mbstring php-zip php-net-socket php-gd php-xml-util php-gettext php-mysql php-bcmath \
 &&	rm -rf /var/lib/apt/lists/*

#setting mariaDB(mySQL). -e is option to run from the command line.
RUN service mysql start \
 && mysql -e "CREATE DATABASE IF NOT EXISTS wpDB;" \
 && mysql -e "CREATE USER IF NOT EXISTS 'wpUSER'@'localhost' IDENTIFIED BY 'dbpass';" \
 && mysql -e "GRANT ALL PRIVILEGES ON wpDB.* TO 'wpUSER'@'localhost' WITH GRANT OPTION;" \
 && mysql -e "FLUSH PRIVILEGES;"

#install wordpress
RUN cd /tmp \
 && wget https://ja.wordpress.org/latest-ja.tar.gz \
 && tar -xvzf latest-ja.tar.gz \
 && mv wordpress /var/www/html/

#install phpMyAdmin
RUN cd /tmp \
 && wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz \
 && tar xvf phpMyAdmin-5.0.2-all-languages.tar.gz \
 && mv phpMyAdmin-5.0.2-all-languages /var/www/html/phpmyadmin

#install entrykit
RUN wget https://github.com/progrium/entrykit/releases/download/v0.4.0/entrykit_0.4.0_Linux_x86_64.tgz \
 && tar -xvzf entrykit_0.4.0_Linux_x86_64.tgz \
 && mv entrykit /bin/entrykit \
 && entrykit --symlink

#setting SSL
#Generate a 2048-bit RSA private key with the genrsa command
#Create a certificate signing request (server.csr) to be signed.
#Create a self-signed server certificate (server.crt) with your own private key (private.key).
RUN mkdir /etc/nginx/ssl \
 && openssl genrsa -out /etc/nginx/ssl/server.key 2048 \
 && openssl req -new -key /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.csr -subj "/C=JP/ST=Tokyo/L=/O=/OU=/CN=localhost" \
 && openssl x509 -days 3650 -req -signkey /etc/nginx/ssl/server.key -in /etc/nginx/ssl/server.csr -out /etc/nginx/ssl/server.crt

# Replacing the configuration file
COPY ./srcs/wp-config.php /var/www/html/wordpress/wp-config.php
COPY ./srcs/default.tmpl /etc/nginx/sites-available/default.tmpl
COPY ./srcs/supervisord.conf /etc/

#authorization change
RUN chown -R www-data:www-data /var/www/html/*

#ENTRYPOINT
# Replace with the tmpl file in the same folder
ENTRYPOINT ["render", "etc/nginx/sites-available/default", "--", "/usr/bin/supervisord"]