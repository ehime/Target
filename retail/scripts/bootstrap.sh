#!/usr/bin/env bash

## Can also be passed via ARGV[0]
DBHOST='localhost'
DBUSER='retailuser'
DBPASS='retailpass'
DBNAME='retail'

DOCROOT='/var/www/html'

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
rm -rf $DOCROOT
mkdir -p /vagrant/httpdocs

ln -fs /vagrant/httpdocs $DOCROOT

# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
Listen 8080
<VirtualHost *:80>
  DocumentRoot "$DOCROOT/public"
  ServerName localhost
  <Directory "$DOCROOT">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:8080>
  DocumentRoot "$DOCROOT/public"
  ServerName localhost
  <Directory "$DOCROOT/public">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

a2enmod rewrite
service apache2 restart

# Mysql
# --------------------


# Install MySQL quietly
echo -e '--> Installing Mysql 5.6'
apt-get -q -y install mysql-server-5.6
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DBNAME}"

mysql -u root -e "
DROP TABLE IF EXISTS \`${DBNAME}\`.\`products\` ;
CREATE TABLE \`${DBNAME}\`.\`products\` (
  \`id\`                  bigint(20)    NOT NULL AUTO_INCREMENT,
  \`title\`               varchar(50)   DEFAULT NULL,
  \`description\`         varchar(255)  DEFAULT NULL,
  \`price\`               decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8"

mysql -u root -e "
LOCK TABLES \`${DBNAME}\`.\`products\` WRITE ;
INSERT INTO \`${DBNAME}\`.\`products\` VALUES
(1, 'pencil',   'its yellow, and slightly chewed on.',     1.99),
(2, 'eraser',   'it erases supposedly',                    1.99),
(3, 'pen',      'some say, its mightier than the sword',   0.99),
(4, 'crayon',   'not edible, but dont tell the kids that', 1.00) ;
UNLOCK TABLES ;"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'${DBHOST}' IDENTIFIED BY '${DBPASS}'"
mysql -u root -e "FLUSH PRIVILEGES"

# Framework
# --------------------
curl -sS https://getcomposer.org/installer |sudo php -- --install-dir=/usr/local/bin --filename=composer

cd $DOCROOT ; echo -e '
{
  "name": "ehime/retail",
  "description": "Simple storefront",
  "keywords":    ["storefront", "vagrant", "aio"],
  "version":     "1.0.0",
  "type":        "library",
  "license":     "MIT",
  "authors": [
    {
      "name": "Jd Daniel",
      "email": "dodomeki@gmail.com"
    }
  ],
  "minimum-stability": "dev",
  "require": {
    "slim/slim": "2.*",
    "php":        ">=5.5.0"
  },
  "require-dev": {
    "phpunit/phpunit": "4.3.5",
    "mockery/mockery": "0.8.*"
  },
  "autoload": {
    "psr-0": {
      "Model":      "src/",
      "Controller": "src/",
      "View":       "src/",
      "Helper":     "src/"
    },
    "autoload-dev": {
      "classmap": [
        "tests/"
      ]
    },
    "config": {
      "preferred-install": "dist"
    }
  }
}
' > composer.json

composer install ; ln -s /vagrant/payload/* $DOCROOT   ## refresh payload, but dont duplicate code...
