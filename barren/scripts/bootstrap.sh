#!/usr/bin/env bash

## Can also be passed via ARGV[0]
DBHOST='localhost'
DBUSER='barrenuser'
DBPASS='barrenpass'
DBNAME='barren'

DOCROOT='/var/www/html'

echo "export APP_PATH=$DOCROOT" >> .bashrc

# Set Perl:locales
# http://serverfault.com/questions/500764/dpkg-reconfigure-unable-to-re-open-stdin-no-file-or-directory
# --------------------
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

export DEBIAN_FRONTEND=noninteractive

# Update Apt
# --------------------
apt-get update

# Install Apache & PHP
# --------------------
apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
apt-get install -y php5-mysqlnd php5-curl php5-xdebug php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-soap

php5enmod mcrypt

# Install GIT
apt-get install -y git

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf $DOCROOT ; mkdir -p /vagrant/httpdocs
ln -fs /vagrant/httpdocs $DOCROOT

# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
Listen 8080
<VirtualHost *:80>
  DocumentRoot "$DOCROOT/public"
  ServerName localhost
  SetEnv APP_PATH $DOCROOT
  <Directory "$DOCROOT">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:8080>
  DocumentRoot "$DOCROOT/public"
  ServerName localhost
  SetEnv APP_PATH $DOCROOT
  <Directory "$DOCROOT/public">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

a2enmod rewrite
service apache2 restart

ln -fs /vagrant/payload/* $DOCROOT   ## refresh payload, but dont duplicate code...
