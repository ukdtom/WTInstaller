#!/bin/sh
#***************************************************************************
# Script that will download the latest version of WebTools, a Plex Toolkit
# 
# Made by dane22, a Plex community member
#
# Asustor version
#
#***************************************************************************

RETURNVAL=0

PLUGIN_DIR="/volume1/Plex/Library/Plex Media Server/Plug-ins" #Plugin dir on AsuStor
RELEASE_LINK="https://api.github.com/repos/dagalufh/WebTools.bundle/releases/latest" # Release info for WebTools on Github

######################################################################
# Get latest release download link, and download that
######################################################################
downloadWT(){
	DownloadURL=$(curl -Lsk $RELEASE_LINK |grep 'tarball_url')
	# Strip all before "http://...
	DownloadURL=${DownloadURL#*:}
	#Strip leading "
	DownloadURL=${DownloadURL#*\"}
	#Strip last " and onwards
	DownloadURL=${DownloadURL%\"*}
	curl -Lsk $DownloadURL -o "$PLUGIN_DIR/wt.tar.gz"
}

######################################################################
# Create WT dir if missing, and then extract. remove tarball afterwards
######################################################################
extractWT(){
	mkdir -p "$PLUGIN_DIR/WebTools.bundle"
	tar -xf "$PLUGIN_DIR/wt.tar.gz" --overwrite --strip 1 -C "$PLUGIN_DIR/WebTools.bundle"
	rm "$PLUGIN_DIR/wt.tar.gz"
}

do_start() {
	if [  -d "$PLUGIN_DIR" ]; then
		# Plugin dir found
		downloadWT
		extractWT
		return 0
	else
		return 1
	fi
}

do_stop() {
    return 0
}

case "$1" in
    start)
        do_start
    ;;
    stop)
        do_stop
    ;;
esac
exit 0
