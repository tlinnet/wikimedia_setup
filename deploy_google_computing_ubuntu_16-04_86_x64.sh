#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying wikimedia on Google Cloud Computing GCC

# Guide taken from:
# https://www.mediawiki.org/wiki/Manual:Running_MediaWiki_on_Debian_or_Ubuntu
# https://help.ubuntu.com/community/MediaWiki
# https://hostpresto.com/community/tutorials/how-to-install-and-configure-mediawiki-on-ubuntu-16-04/
# https://www.rosehosting.com/blog/how-to-install-mediawiki-on-an-ubuntu-16-04-vps/

# Install apt-get packages
function doaptget {
    sudo apt-get -y update
    sudo apt-get -y upgrade

    # Install lamp
    sudo apt-get -y install tasksel
    sudo tasksel install lamp-server

    # Install LAMP server
    sudo apt-get -y install apache2 mysql-server php php-mysql libapache2-mod-php php-xml php-mbstring
    sudo apt-get -y install php-curl php-json php-cgi

    # Additional
    #Alternative PHP Cache	php-apcu or php5-apcu	Modern MediaWiki versions will automatically take advantage of this being installed for improved performance.
    sudo apt-get -y install php-apcu

    # PHP Unicode normalization	php-intl or php5-intl	MediaWiki will fallback to a slower PHP implementation if not available.
    sudo apt-get -y install php-intl

    # PHP GD library	php-gd or php5-gd	Alternative to ImageMagick for image thumbnailing.
    sudo apt-get -y install php-gd

    # PHP command-line	php-cli or php5-cli	Ability to run PHP commands from the command line, which is useful for debugging and running maintenance scripts.
    sudo apt-get -y install php-cli

    # MediaWiki can be configured to send email messages for various functions. You will need to install some additional packages:
    sudo apt-get -y install php-pear
    sudo pear install mail
    sudo pear install Net_SMTP

    # Zip tools
    sudo apt-get -y install zip unzip php-zip

    # ImageMagick	imagemagick	Image thumbnailing.
    sudo apt-get -y install imagemagick

    # Inkscape	inkscape	Alternative means of SVG thumbnailing, than ImageMagick. Sometimes it will render SVGs better if originally created in Inkscape.
    sudo apt-get -y install inkscape

    # Install packages for: https://www.mediawiki.org/wiki/Extension:Math
    # https://www.mediawiki.org/wiki/Extension:Math/advancedSettings
    sudo apt-get -y install texlive-latex-recommended texlive-fonts-recommended texlive-lang-greek dvipng
    sudo apt-get -y install build-essential ocaml

    # https://www.mediawiki.org/wiki/Extension:PdfHandler
    sudo apt-get -y install xpdf-utils ghostscript imagemagick

    # Install lynx
    sudo apt-get -y install lynx
}

# This program enables you to improve the security of your MySQL
function domysqlsecure {
    mysql_secure_installation
}

function dogetvar {
    DEFDOMAIN="domain.com"
    unset DOMAIN
    read -p "What is the domain for the site [$DEFDOMAIN]:" DOMAIN
    DOMAIN=${DOMAIN:-$DEFDOMAIN}
    echo -e "You entered: $DOMAIN"
    echo ""

    DEFDATABASE=`echo $DOMAIN | tr "." _`
    unset DATABASE
    read -p "What should the MySQL database the site be named [$DEFDATABASE]:" DATABASE
    DATABASE=${DATABASE:-$DEFDATABASE}
    echo -e "You entered: $DATABASE"
    echo ""

    DEFUSERDB="user_$DATABASE"
    unset USERDB
    read -p "What should the MySQL username for the database be named [$DEFUSERDB]:" USERDB
    USERDB=${USERDB:-$DEFUSERDB}
    echo -e "You entered: $USERDB"
    echo ""

    DEFUSERDBPASSWD="PASSWORD"
    unset USERDBPASSWD
    read -p "What should the password for the MySQL username be [$DEFUSERDBPASSWD]:" USERDBPASSWD
    USERDBPASSWD=${USERDBPASSWD:-$DEFUSERDBPASSWD}
    echo -e "You entered: $USERDBPASSWD"
    echo ""

    DEFROOTPASSWD="PASSWORD"
    unset ROOTPASSWD
    read -p "What is the password for the MySQL root? [$DEFROOTPASSWD]:" ROOTPASSWD
    ROOTPASSWD=${ROOTPASSWD:-$DEFROOTPASSWD}
    echo -e "You entered: $ROOTPASSWD"
    echo ""
}

# Change mysql settings
# Get inspiration from: http://homeroam.wikidot.com/daloradius-0-9-9#toc6
function domysql {
    # Create new database
    mysql -u root -p"$ROOTPASSWD" -e "CREATE DATABASE $DATABASE CHARACTER SET utf8;"
    mysql -u root -p"$ROOTPASSWD" -e 'show databases;'

    # Create user
    mysql -h localhost -u root -p"$ROOTPASSWD" -e "uninstall plugin validate_password;"
    mysql -u root -p"$ROOTPASSWD" -e "CREATE USER '$USERDB'@'localhost' IDENTIFIED BY '$USERDBPASSWD';"

    # See the users grants
    mysql -u root -p"$ROOTPASSWD" -e 'select host, user from mysql.user;'
    mysql -u root -p"$ROOTPASSWD" -e "GRANT ALL PRIVILEGES ON $DATABASE.* TO '$USERDB'@'localhost';"
    mysql -u root -p"$ROOTPASSWD" -e 'SELECT user, host, db, select_priv, insert_priv, grant_priv FROM mysql.db'
    mysql -u root -p"$ROOTPASSWD" -e 'FLUSH PRIVILEGES;'
}

# Get latest compiled version of wikimedia composer
function dogetcomposer {
    cd $HOME
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    sudo mv composer.phar /usr/local/bin/composer
}

# Get latest compiled version of wikimedia
function dogetwikimedia {
    # See https://www.mediawiki.org/wiki/Download_from_Git
    sudo chown -R $USER:www-data /var/www/html

    if [ ! -d "/var/www/html/$DOMAIN" ]; then
        cd /var/www/html
        git clone https://gerrit.wikimedia.org/r/p/mediawiki/core.git $DOMAIN

        # Get extensions
        cd /var/www/html/$DOMAIN
        rm -rf extensions
        git clone https://gerrit.wikimedia.org/r/p/mediawiki/extensions.git
        cd extensions
        git submodule update --init --recursive

        # Get skins
        cd /var/www/html/$DOMAIN
        rm -rf skins
        git clone https://gerrit.wikimedia.org/r/p/mediawiki/skins.git
        cd skins
        git submodule update --init --recursive

        # Enable composer
        cd /var/www/html/$DOMAIN
        composer install --no-dev

        # https://www.mediawiki.org/wiki/Extension:Math/advancedSettings#On_a_host_with_full_shell_access
        # Build texvc
        cd /var/www/html/$DOMAIN/extensions/Math
        make
        cd $HOME
    fi
}

# Change apache settings
function doapache {
    # Change Maximum upload file size
    sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 200M/' /etc/php/7.0/apache2/php.ini
    grep "upload_max_filesize" /etc/php/7.0/apache2/php.ini

    # Enable Apache rewrite module
    sudo a2enmod rewrite
    sudo service apache2 restart
}

function doapacheweb {
    # Disable default site
    cat /etc/apache2/sites-enabled/000-default.conf
    sudo a2dissite 000-default

    cd $HOME
    echo '<VirtualHost *:80>' > $DOMAIN.conf
    echo "DocumentRoot /var/www/html/${DOMAIN}/" >> $DOMAIN.conf
    echo "ServerName ${DOMAIN}/" >> $DOMAIN.conf
    echo "ServerAlias www.${DOMAIN}/" >> $DOMAIN.conf
    echo "<Directory /var/www/html/${DOMAIN}/>" >> $DOMAIN.conf
    echo "Options FollowSymLinks" >> $DOMAIN.conf
    echo "AllowOverride All" >> $DOMAIN.conf
    echo "Order allow,deny" >> $DOMAIN.conf
    echo "allow from all" >> $DOMAIN.conf
    echo '</Directory>' >> $DOMAIN.conf
    echo "ErrorLog /var/log/apache2/${DOMAIN}-error_log" >> $DOMAIN.conf
    echo "CustomLog /var/log/apache2/${DOMAIN}-access_log common" >> $DOMAIN.conf
    echo '</VirtualHost>' >> $DOMAIN.conf
    cat $DOMAIN.conf
    #
    sudo cp $DOMAIN.conf /etc/apache2/sites-available/
    ls -la /etc/apache2/sites-available/
    sudo a2ensite $DOMAIN
    sudo service apache2 restart
}

# Make home bin
function dobin {
  mkdir -p $HOME/bin
  echo '' >> $HOME/.bashrc
  echo 'export PATH=$PATH:$HOME/bin' >> $HOME/.bashrc
  source $HOME/.bashrc
}

# Combine functions
function doinstall {
    doaptget

    domysqlsecure
    dogetvar
    domysql

    dogetcomposer
    dogetwikimedia

    doapache
    doapacheweb

    dobin

    echo "Please visit for installation: http://SERVER-IP/$DOMAIN"
    echo "Your domain is: $DOMAIN"
    echo "Your MySQL database is: $DATABASE"
    echo "Your MySQL username is: $USERDB"
}

