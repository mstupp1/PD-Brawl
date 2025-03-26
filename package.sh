#!/bin/bash

# PD Brawl packaging script
# Creates a .love file for distribution

echo "Packaging PD Brawl into .love file..."

# Create a temporary directory
mkdir -p ./build

# Create the .love file (zip with .love extension)
# Include all necessary game files
zip -9 -r ./build/pd-brawl.love main.lua conf.lua README.md src/ assets/

echo "Package created at ./build/pd-brawl.love"
echo "To run the game, use: love ./build/pd-brawl.love" 