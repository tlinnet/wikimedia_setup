#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying wikimedia on Google Cloud Computing GCC

# Install apt-get packages
function doaptget {
    sudo apt-get -y update
    sudo apt-get -y upgrade

    # Install LAMP server
    sudo apt-get -y install apache2 mysql-server php php-mysql libapache2-mod-php php-xml php-mbstring

    # Additional
    #Alternative PHP Cache	php-apcu or php5-apcu	Modern MediaWiki versions will automatically take advantage of this being installed for improved performance.
    sudo apt-get -y install php-apcu

    # PHP Unicode normalization	php-intl or php5-intl	MediaWiki will fallback to a slower PHP implementation if not available.
    sudo apt-get -y install php-intl

    # ImageMagick	imagemagick	Image thumbnailing.
    sudo apt-get -y install imagemagick

    # Inkscape	inkscape	Alternative means of SVG thumbnailing, than ImageMagick. Sometimes it will render SVGs better if originally created in Inkscape.
    sudo apt-get -y install inkscape

    # PHP GD library	php-gd or php5-gd	Alternative to ImageMagick for image thumbnailing.
    sudo apt-get -y install php-gd

    # PHP command-line	php-cli or php5-cli	Ability to run PHP commands from the command line, which is useful for debugging and running maintenance scripts.
    sudo apt-get -y install php-cli

    # Install lynx
    sudo apt-get -y install lynx
}

function dogetversion {
    # From the wiki, get current versions
    WIKIV=`lynx -dump "https://www.mediawiki.org/wiki/Download" | grep "Download MediaWiki" | head -n 1 | cut -d"]" -f 3 | cut -d" " -f3`
    WIKIVT=`echo $WIKIV | cut -d"." -f1-2`

    echo "Current version of wikimedia is: $WIKIV"
}


# Get latest compiled version of relax
function dogetwikimedia {
    mkdir -p "$HOME/Downloads"
    cd "$HOME/Downloads"
    if [ ! -d "$HOME/Downloads/mediawiki-$WIKIV" ]; then
        curl https://releases.wikimedia.org/mediawiki/$WIKIVT/mediawiki-$WIKIV.tar.gz -o mediawiki-$WIKIV.tar.gz
        tar -xvzf mediawiki-$WIKIV.tar.gz
        rm mediawiki-$WIKIV.tar.gz
    fi

    if [ ! -d "/var/lib/mediawiki" ]; then
        sudo mkdir -p /var/lib/mediawi
        sudo mv "$HOME/Downloads/mediawiki-$WIKIV" "/var/lib/mediawiki"
    fi
}

# Combine functions
function doinstall {
    dogetversion
    dogetwikimedia
}