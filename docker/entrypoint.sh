#!/bin/bash -e
cd /home/mpvbuilder/libs
if [ "$1" = shell ]; then
	exec /bin/bash
fi
exec ./build.sh "$@"
