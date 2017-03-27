#!/bin/bash
# -*- coding: UTF-8 -*-
# Script for deploying wikimedia on Google Cloud Computing GCC

# Install apt-get packages
function doaptget {
    sudo apt-get update
    sudo apt-get upgrade
}