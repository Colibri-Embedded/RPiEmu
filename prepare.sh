#!/bin/bash
rm -f sdcard/bundles/*-bundle*
cp ../colibri-buildroot/output/sdcard/bundles/* sdcard/bundles/
sudo ./create-sdcard.sh
sudo ./copy2sdcard.sh

