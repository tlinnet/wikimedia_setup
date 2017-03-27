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

    # ImageMagick	imagemagick	Image thumbnailing.
    sudo apt-get -y install imagemagick

    # Inkscape	inkscape	Alternative means of SVG thumbnailing, than ImageMagick. Sometimes it will render SVGs better if originally created in Inkscape.
    sudo apt-get -y install inkscape

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

    DEFUSER="user_$DATABASE"
    unset USER
    read -p "What should the MySQL username for the database be named [$DEFUSER]:" USER
    USER=${USER:-$DEFUSER}
    echo -e "You entered: $USER"
    echo ""

    DEFUSERPASSWD="PASSWORD"
    unset USERPASSWD
    read -p "What should the password for the MySQL username be [$DEFUSERPASSWD]:" USERPASSWD
    USERPASSWD=${USERPASSWD:-$DEFUSERPASSWD}
    echo -e "You entered: $USERPASSWD"
    echo ""

    DEFROOTPASSWD="PASSWORD"
    unset ROOTPASSWD
    read -p "What is the password for the MySQL root? [$DEFROOTPASSWD]:" ROOTPASSWD
    ROOTPASSWD=${ROOTPASSWD:-$DEFROOTPASSWD}
    echo -e "You entered: $ROOTPASSWD"
    echo ""
}

# Change mysql settings
function domysql {
    # Create new database
    mysql -u root -p"$ROOTPASSWD" -e "CREATE DATABASE $DATABASE CHARACTER SET utf8;"
    mysql -u root -p"$ROOTPASSWD" -e 'show databases;'

    # Create user
    mysql -h localhost -u root -p"$ROOTPASSWD" -e "uninstall plugin validate_password;"
    mysql -u root -p"$ROOTPASSWD" -e "CREATE USER '$USER'@'localhost' IDENTIFIED BY '$USERPASSWD';"

    # See the users grants
    mysql -u root -p"$ROOTPASSWD" -e 'select host, user from mysql.user;'
    mysql -u root -p"$ROOTPASSWD" -e "GRANT ALL PRIVILEGES ON $DATABASE.* TO '$USER'@'localhost';"
    mysql -u root -p"$ROOTPASSWD" -e 'SELECT user, host, db, select_priv, insert_priv, grant_priv FROM mysql.db'
    mysql -u root -p"$ROOTPASSWD" -e 'FLUSH PRIVILEGES;'
}

# From the wiki, get current versions
function dogetversion {
    WIKIV=`lynx -dump "https://www.mediawiki.org/wiki/Download" | grep "Download MediaWiki" | head -n 1 | cut -d"]" -f 3 | cut -d" " -f3`
    WIKIVT=`echo $WIKIV | cut -d"." -f1-2`
    echo "Current version of wikimedia is: $WIKIV"
}


# Get latest compiled version of wikimedia
function dogetwikimedia {
    mkdir -p "$HOME/Downloads"
    cd "$HOME/Downloads"
    if [ ! -d "$HOME/Downloads/mediawiki-$WIKIV" ]; then
        curl https://releases.wikimedia.org/mediawiki/$WIKIVT/mediawiki-$WIKIV.tar.gz -o mediawiki-$WIKIV.tar.gz
        tar -xvzf mediawiki-$WIKIV.tar.gz
        rm mediawiki-$WIKIV.tar.gz
    fi

    # Move the files
    if [ ! -d "/var/www/html/mediawiki" ]; then
        sudo mkdir -p /var/www/html/mediawi
        sudo mv "$HOME/Downloads/mediawiki-$WIKIV" "/var/www/html/mediawiki"
    fi

    #Change the ownership of mediawiki directory to www-data:
    sudo www-data:www-data -R /var/www/html/mediawiki
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



# Combine functions
function doinstall {
    doaptget

    domysqlsecure
    dogetvar
    domysql

    dogetversion
    dogetwikimedia
    doapache

    echo "Please visit for installation: http://SERVER-IP/mediawiki"
}

