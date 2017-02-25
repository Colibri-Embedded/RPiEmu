#!/bin/bash
########################################################################
#
# RaspberryPi emulator.
#
# Copyright (C) 2016 Daniel Kesler <kesler.daniel@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#    
########################################################################
## @file   initialize.sh
## @author Daniel Kesler <kesler.daniel@gmail.com>
## @brief
## @copyright GPLv2
## @version 0.1
########################################################################

initialize_project() {
	echo "new project"
	mkdir -p $1
	
	cp examples/run.py    $1/
	
	mkdir -p $1/models
	touch $1/models/__init__.py
	cp -R examples/models/example.py $1/models
	
	echo "RPIEMU_RUN = $1/run.py" > $1/config.mk
	
	link_project $1
}

link_project() {
	echo "Linking '$1/config.mk' to emulator."
	echo "EXTERNAL_MK = ${1}/config.mk" > external.mk
}

DEST=${1}

if [ -f "${DEST}/config.mk" ]; then
	echo "Existing project found."
	link_project $DEST
else
	initialize_project $DEST
fi
