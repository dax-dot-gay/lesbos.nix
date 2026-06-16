#! /usr/bin/env bash

cd $(git rev-parse --show-toplevel)

if [ ! -f "scripts/lobash.bash" ]; then
    echo "Downloading lobash..."
    VERSION=v0.7.0
    git clone --depth 1 --branch $VERSION https://github.com/adoyle-h/lobash.git tmp-lobash
    cd tmp-lobash

    echo "Building to scripts/lobash.bash..."
    BASHVER=5.3.9 ./build ../scripts/lobash.bash
    
    echo "Removing tmpfiles"
    cd ..
    rm -rf tmp-lobash
else
    echo "lobash already exists, skipping"
fi