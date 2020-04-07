#!/bin/bash

#######################################################################################################################
#
#	Merge raspiBackup config files
#
#######################################################################################################################
#
#   Copyright (c) 2020 framp at linux-tips-and-tricks dot de
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################

MYSELF=${0##*/}
MYNAME=${MYSELF%.*}
VERSION="0.1"

set +u;GIT_DATE="$Date: 2020-04-07 20:48:34 +0200$"; set -u
GIT_DATE_ONLY=${GIT_DATE/: /}
GIT_DATE_ONLY=$(cut -f 2 -d ' ' <<< $GIT_DATE)
GIT_TIME_ONLY=$(cut -f 3 -d ' ' <<< $GIT_DATE)
set +u;GIT_COMMIT="$Sha1: 5a6e009$";set -u
GIT_COMMIT_ONLY=$(cut -f 2 -d ' ' <<< $GIT_COMMIT | sed 's/\$//')

GIT_CODEVERSION="$MYSELF $VERSION, $GIT_DATE_ONLY/$GIT_TIME_ONLY - $GIT_COMMIT_ONLY"

ORIG_CONFIG="/usr/local/etc/raspiBackup.conf"
BACKUP_CONFIG="/usr/local/etc/raspiBackup.conf.bak"
NEW_CONFIG="/usr/local/etc/raspiBackup.conf.new"

PRFX="# >>> CHANGED <<< "

if (( $# < 1 )); then
	echo "Missing new config file"
	exit 1
fi

if [[ ! -f $1 ]]; then
	echo "New config file $1 does not exist"
	exit 1
fi

if (( $UID != 0 )); then
	echo "Call script as root with 'sudo $0 $@'"
	exit 1
fi

# save old config
echo "Saving old config $ORIG_CONFIG in $BACKUP_CONFIG"
cp $ORIG_CONFIG $BACKUP_CONFIG

rm -f $NEW_CONFIG &>/null

# process NEW CONFIG FILE
echo "Merging old config $ORIG_CONFIG and new config $1"
while read line; do
	if [[ -n "$line" && ! "$line" =~ ^# ]]; then
		KW="$(cut -d= -f1 <<< "$line")"
		[[ "$KW" == "VERSION_CONF" ]] && continue

		echo "$line" >> $NEW_CONFIG

		NC="$(grep "$KW=" $ORIG_CONFIG)"
		if (( $? == 0 )); then
			if [[ "$line" != "$NC" ]]; then
				NC="$(cut -d= -f2- <<< "$NC" )"
				echo "$PRFX $KW=$NC" >> $NEW_CONFIG
			fi
		fi
	else
		echo "$line" >> $NEW_CONFIG
	fi
done < "$1"

UUID="$(grep "^UUID" $ORIG_CONFIG)"
echo "" >> $NEW_CONFIG
echo "# GENERATED - DO NOT DELETE" >> $NEW_CONFIG
echo "$UUID" >> $NEW_CONFIG

echo "Merged config files"

echo "Backup config file: $BACKUP_CONFIG"
echo "Merged config file: $NEW_CONFIG"
echo "Now edit $NEW_CONFIG and copy it to $ORIG_CONFIG"

