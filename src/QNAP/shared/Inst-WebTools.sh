#!/bin/sh
#****************************************************************
# This will download the latest version of WebTools on a QNAP
# After downloading, it'll extraxt and install the plugin
#
# Webtools is a Plex Media Server PlugIn
#
# Written by dane22, a Plex Community member
#****************************************************************

CONF=/etc/config/qpkg.conf			# conf file for all qpkg's
QPKG_NAME="QNAP-WT-Install"				# name of this file
TARGETAPP='Plex Media Server'			# name of the target application
PMSFULLPATH=$(getcfg -f $CONF 'PlexMediaServer' Install_path)			# Install dir of PMS
PLUGIN_DIR="$PMSFULLPATH/Library/Plex Media Server/Plug-ins"
RELEASE_LINK="https://api.github.com/repos/dagalufh/WebTools.bundle/releases/latest" # Release info for WebTools on Github

######################################################################
# Get latest release download link, and download that
######################################################################
downloadWT(){
	# Let's start by finding the browser_download_url
	# Sadly, QNAP can not nativly extract the download binary, so we instead need to fetch the tarball
	# That again means, that QNAP'ers using this is not counted :-(
#	DownloadURL=$(/sbin/curl -Lsk $RELEASE_LINK |grep 'browser_download_url')
	DownloadURL=$(/sbin/curl -Lsk $RELEASE_LINK |grep 'tarball_url')
	# Strip start part of line
	DownloadURL=$(sed 's/"tarball_url": "//g' <<< $DownloadURL)
	# Strip end part of the response
  DownloadURL=$(sed s'/..$//' <<< $DownloadURL)
	/sbin/log_tool -t 0 -a "About to download the file $DownloadURL"
	# Download the darn thingy
	/sbin/curl -Lsk $DownloadURL -o "$PLUGIN_DIR/wt.tar.gz"
}

######################################################################
# Create WT dir if missing, and then extract. remove tarball afterwards
######################################################################
extractWT(){
	mkdir -p "$PLUGIN_DIR/WebTools.bundle"
	tar -xf "$PLUGIN_DIR/wt.tar.gz" --overwrite --strip 1 -C "$PLUGIN_DIR/WebTools.bundle"
	rm "$PLUGIN_DIR/wt.tar.gz"
#	unzip -oq "$PLUGIN_DIR/wt.zip" -d "$PLUGIN_DIR/WebTools.bundle"
}

######################################################################
# Main code
######################################################################

case "$1" in
  start)
	ENABLED=$(/sbin/getcfg $QPKG_NAME Enable -u -d FALSE -f $CONF)
	if [ "$ENABLED" != "TRUE" ]; then
		echo "$QPKG_NAME is disabled."
		exit 1
	fi
	: ADD START ACTIONS HERE
	# Get dir of this script
	DIR=$(/sbin/getcfg $QPKG_NAME Install_Path -d FALSE -f $CONF)
	/sbin/log_tool -t 0 -a "Starting $QPKG_NAME from $DIR"
	downloadWT
	extractWT
	/sbin/setcfg PlexInst Enable FALSE -f /etc/config/qpkg.conf
    ;;

  stop)
    : ADD STOP ACTIONS HERE
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
