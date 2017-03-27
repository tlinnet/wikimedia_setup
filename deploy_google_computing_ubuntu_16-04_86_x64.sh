#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying wikimedia on Google Cloud Computing GCC

# Install apt-get packages
function doaptget {
    sudo apt-get -y update
    sudo apt-get -y upgrade
}