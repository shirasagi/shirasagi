#!/bin/bash
driver_version=$(wget -O - "https://chromedriver.storage.googleapis.com/LATEST_RELEASE")
wget -O $HOME/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$driver_version/chromedriver_linux64.zip
cd $HOME && unzip $HOME/chromedriver_linux64.zip
