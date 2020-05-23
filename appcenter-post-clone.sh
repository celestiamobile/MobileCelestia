#!/usr/bin/env bash

cd $APPCENTER_SOURCE_DIRECTORY/..

# Clone the Celestia repo (modified)
git clone https://github.com/eyvallah/Celestia
cd Celestia
git submodule update --init
cd ..

# Clone the CelestiaCore repo
git clone https://${GITHUB_USERNAME}:${GITHUB_ACCESS_TOKEN}@github.com/eyvallah/CelestiaCore
cd CelestiaCore
git submodule update --init
ln -sf libs/iOS thirdparty
cd ..

# Install gettext, needed for translation
brew install gettext

# Download AppCenter
cd $APPCENTER_SOURCE_DIRECTORY
brew install wget
APPCENTER_VERSION="3.2.0"
wget https://github.com/microsoft/appcenter-sdk-apple/releases/download/${APPCENTER_VERSION}/AppCenter-SDK-Apple-${APPCENTER_VERSION}.zip
unzip -qq AppCenter-SDK-Apple-${APPCENTER_VERSION}.zip 'AppCenter-SDK-Apple/iOS/*'
ln -sf AppCenter-SDK-Apple/iOS AppCenter
