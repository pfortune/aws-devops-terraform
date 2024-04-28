#!/bin/bash
set -xe  # Log each command and exit if any command fails

cd /var/www/boardbuddy

# Start the Boardbuddy app in the background
npm run start &