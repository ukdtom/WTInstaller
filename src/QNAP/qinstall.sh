#!/bin/sh
############################################################################
#
# $Id: qinstall.sh 360 2011-07-17 09:34:20Z micke $
#
# A QPKG installation script for QDK
#
# Copyright (C) 2009,2010 QNAP Systems, Inc.
# Copyright (C) 2010,2011 Michael Nordstrom
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
############################################################################

##### Command definitions #####
CMD_AWK="/bin/awk"
CMD_CAT="/bin/cat"
CMD_CHMOD="/bin/chmod"
CMD_CHOWN="/bin/chown"
CMD_CP="/bin/cp"
CMD_CUT="/bin/cut"
CMD_DATE="/bin/date"
CMD_ECHO="/bin/echo"
CMD_EXPR="/usr/bin/expr"
CMD_FIND="/usr/bin/find"
CMD_GETCFG="/sbin/getcfg"
CMD_GREP="/bin/grep"
CMD_GZIP="/bin/gzip"
CMD_HOSTNAME="/bin/hostname"
CMD_LN="/bin/ln"
CMD_LOG_TOOL="/sbin/log_tool"
CMD_MD5SUM="/bin/md5sum"
CMD_MKDIR="/bin/mkdir"
CMD_MV="/bin/mv"
CMD_RM="/bin/rm"
CMD_RMDIR="/bin/rmdir"
CMD_SED="/bin/sed"
CMD_SETCFG="/sbin/setcfg"
CMD_SLEEP="/bin/sleep"
CMD_SORT="/usr/bin/sort"
CMD_SYNC="/bin/sync"
CMD_TAR="/bin/tar"
CMD_TOUCH="/bin/touch"
CMD_WGET="/usr/bin/wget"
CMD_WLOG="/sbin/write_log"
CMD_XARGS="/usr/bin/xargs"
CMD_7Z="/usr/local/sbin/7z"

##### System definitions #####
SYS_EXTRACT_DIR="$(pwd)"
SYS_CONFIG_DIR="/etc/config"
SYS_INIT_DIR="/etc/init.d"
SYS_STARTUP_DIR="/etc/rcS.d"
SYS_SHUTDOWN_DIR="/etc/rcK.d"
SYS_RSS_IMG_DIR="/home/httpd/RSS/images"
SYS_QPKG_DATA_FILE_GZIP="./data.tar.gz"
SYS_QPKG_DATA_FILE_BZIP2="./data.tar.bz2"
SYS_QPKG_DATA_FILE_7ZIP="./data.tar.7z"
SYS_QPKG_DATA_CONFIG_FILE="./conf.tar.gz"
SYS_QPKG_DATA_MD5SUM_FILE="./md5sum"
SYS_QPKG_DATA_PACKAGES_FILE="./Packages.gz"
SYS_QPKG_CONFIG_FILE="$SYS_CONFIG_DIR/qpkg.conf"
SYS_QPKG_CONF_FIELD_QPKGFILE="QPKG_File"
SYS_QPKG_CONF_FIELD_NAME="Name"
SYS_QPKG_CONF_FIELD_VERSION="Version"
SYS_QPKG_CONF_FIELD_ENABLE="Enable"
SYS_QPKG_CONF_FIELD_DATE="Date"
SYS_QPKG_CONF_FIELD_SHELL="Shell"
SYS_QPKG_CONF_FIELD_INSTALL_PATH="Install_Path"
SYS_QPKG_CONF_FIELD_CONFIG_PATH="Config_Path"
SYS_QPKG_CONF_FIELD_WEBUI="WebUI"
SYS_QPKG_CONF_FIELD_WEBPORT="Web_Port"
SYS_QPKG_CONF_FIELD_SERVICEPORT="Service_Port"
SYS_QPKG_CONF_FIELD_SERVICE_PIDFILE="Pid_File"
SYS_QPKG_CONF_FIELD_AUTHOR="Author"
SYS_QPKG_CONF_FIELD_RC_NUMBER="RC_Number"
# The following variables are assigned values at run-time.
SYS_HOSTNAME=$($CMD_HOSTNAME)
# Data file name (one of SYS_QPKG_DATA_FILE_GZIP, SYS_QPKG_DATA_FILE_BZIP2,
# or SYS_QPKG_DATA_FILE_7ZIP)
SYS_QPKG_DATA_FILE=
# Base location.
SYS_QPKG_BASE=""
# Base location of QPKG installed packages.
SYS_QPKG_INSTALL_PATH=""
# Location of installed software.
SYS_QPKG_DIR=""
# If the QPKG should be enabled or disabled after the installation/upgrade.
SYS_QPKG_SERVICE_ENABLED=""
# Architecture of the device the QPKG is installed on.
SYS_CPU_ARCH=""
# Name and location of system shares
SYS_PUBLIC_SHARE=""
SYS_PUBLIC_PATH=""
SYS_DOWNLOAD_SHARE=""
SYS_DOWNLOAD_PATH=""
SYS_MULTIMEDIA_SHARE=""
SYS_MULTIMEDIA_PATH=""
SYS_RECORDINGS_SHARE=""
SYS_RECORDINGS_PATH=""
SYS_USB_SHARE=""
SYS_USB_PATH=""
SYS_WEB_SHARE=""
SYS_WEB_PATH=""
# Path to ipkg or opkg package tool if installed.
CMD_PKG_TOOL=

###################
# QPKG definitions
###################
. qpkg.cfg

###########################################
# System messages
###########################################
SYS_MSG_FILE_NOT_FOUND="Data file not found."
SYS_MSG_FILE_ERROR="Data file error."
SYS_MSG_PUBLIC_NOT_FOUND="Public share not found."
SYS_MSG_FAILED_CONFIG_RESTORE="Failed to restore saved configuration data."

######################################
# Inform web interface about progress
######################################
set_progress(){
	$CMD_ECHO ${1:--1} > /tmp/update_process
}
set_progress_begin(){
	set_progress 0
}
set_progress_before_install(){
	set_progress 1
}
set_progress_after_install(){
	set_progress 2
}
set_progress_end(){
	set_progress 3
}
set_progress_fail(){
	set_progress -1
}

#####################################
# Message to terminal and system log
#####################################
log() {
	local write_msg="$CMD_LOG_TOOL -t0 -uSystem -p127.0.0.1 -mlocalhost -a"
	[ -n "$1" ] && $CMD_ECHO "$1" && $write_msg "$1"
}

#############################################
# Warning message to terminal and system log
#############################################
warn_log() {
	local write_warn="$CMD_LOG_TOOL -t1 -uSystem -p127.0.0.1 -mlocalhost -a"
	[ -n "$1" ] && $CMD_ECHO "$1" 1>&2 && $write_warn "$1"
}

###################################################################
# Error message to terminal and system log. Also cleans up after a
# failed installation. This function terminates the installation.
###################################################################
err_log(){
	local write_err="$CMD_LOG_TOOL -t2 -uSystem -p127.0.0.1 -mlocalhost -a"
	local message="$QPKG_NAME $QPKG_VER installation failed. $1"
	$CMD_ECHO "$message" 1>&2
	$write_err "$message"

	# Any backed up configuration files are restored to be available for
	# a new upgrade attempt.
	restore_config

	set_progress_fail
	exit 1
}

####################
# Extract data file
####################
extract_data(){
 	[ -n "$1" ] || return 1
	local archive="$1"
	local root_dir="${2:-$SYS_QPKG_DIR}"
	case "$archive" in
	*.gz|*.bz2)
		$CMD_TAR xvf "$archive" -C "$root_dir" 2>/dev/null >>$SYS_QPKG_DIR/.list || err_log "$SYS_MSG_FILE_ERROR"
		;;
	*.7z)
		$CMD_7Z x -so "$archive" 2>/dev/null | $CMD_TAR xv -C "$root_dir" 2>/dev/null >>$SYS_QPKG_DIR/.list || err_log "$SYS_MSG_FILE_ERROR"
		;;
	*)
		err_log "$SYS_MSG_FILE_ERROR"
	esac
}

#############################
# Extract extra config files
#############################
extract_config(){
	if [ -f $SYS_QPKG_DATA_CONFIG_FILE ]; then
		$CMD_TAR xvf $SYS_QPKG_DATA_CONFIG_FILE -C / 2>/dev/null | $CMD_SED 's/\.//' 2>/dev/null >>$SYS_QPKG_DIR/.list || err_log "$SYS_MSG_FILE_ERROR"
	fi
}

####################################
# Restore saved configuration files
####################################
restore_config(){
	if [ -f "$SYS_TAR_CONFIG" ]; then
		$CMD_TAR xf $SYS_TAR_CONFIG -C / 2>/dev/null || warn_log "$SYS_MSG_FAILED_CONFIG_RESTORE"
		$CMD_RM $SYS_TAR_CONFIG
	fi
}

############################
# Store configuration files
############################
store_config(){
	# Tag configuration files for later removal.
	$CMD_SED -i "/\[$QPKG_NAME\]/,/^\[/s/^cfg:/^&/" $SYS_QPKG_CONFIG_FILE 2>/dev/null

	SYS_TAR_CONFIG="$SYS_QPKG_INSTALL_PATH/${QPKG_NAME}_$$.tar"
	local new_md5sum=
	local orig_md5sum=
	local current_md5sum=
	local qpkg_config=$($CMD_SED -n '/^QPKG_CONFIG/s/QPKG_CONFIG="\(.*\)"/\1/p' qpkg.cfg)
	for file in $qpkg_config
	do
		new_md5sum=$($CMD_GETCFG "" "$file" -f $SYS_QPKG_DATA_MD5SUM_FILE)
		orig_md5sum=$($CMD_GETCFG "$QPKG_NAME" "^cfg:$file" -f $SYS_QPKG_CONFIG_FILE)
		set_qpkg_config "$file" "$new_md5sum"
		# Files relative to QPKG directory are changed to full path.
		[ -z "${file##/*}" ] || file="$SYS_QPKG_DIR/$file"
		current_md5sum=$($CMD_MD5SUM "$file" 2>/dev/null | $CMD_CUT -d' ' -f1)
		if [ "$orig_md5sum" = "$current_md5sum" ] ||
		   [ "$new_md5sum" = "$current_md5sum" ]; then
			: Use new file
		elif [ -f $file ]; then
			if [ -z "$orig_md5sum" ]; then
				$CMD_MV $file ${file}.qdkorig
				warn_log "$file is saved as ${file}.qdkorig"
			elif [ "$orig_md5sum" = "$new_md5sum" ]; then
				$CMD_TAR rf $SYS_TAR_CONFIG $file 2>/dev/null
			else
				$CMD_MV $file ${file}.qdksave
				warn_log "$file is saved as ${file}.qdksave"
			fi
		fi
	done

	# Remove obsolete configuration files.
	$CMD_SED -i "/\[$QPKG_NAME\]/,/^\[/{/^^cfg:/d}" $SYS_QPKG_CONFIG_FILE 2>/dev/null
}

#####################################################################
# Add given configuration file and md5sum to SYS_QPKG_CONFIG_FILE if
# not already added.
######################################################################
add_qpkg_config(){
	[ -n "$1" ] && [ -n "$2" ] || return 1
	local file="$1"
	local md5sum="$2"

	$CMD_ECHO "$file" >>$SYS_QPKG_DIR/.list
	$CMD_GETCFG "$QPKG_NAME" "cfg:$file" -f $SYS_QPKG_CONFIG_FILE >/dev/null || \
		set_qpkg_config $file $md5sum
}

#################################################
# Remove specified file or directory (if empty).
#################################################
remove_file_and_empty_dir(){
	[ -n "$1" ] || return 1
	local file=
	# Files relative to QPKG directory are changed to full path.
	if [ -n "${1##/*}" ]; then
		file="$SYS_QPKG_DIR/$1"
	else
		file="$1"
	fi
	if [ -f "$file" ]; then
		$CMD_RM -f "$file"
	elif [ -d "$file" ]; then
		$CMD_RMDIR "$file" 2>/dev/null
	fi
}

################################################################
# Remove obsolete files by comparing old and new list of files.
################################################################
remove_obsolete_files(){
	if [ -f $SYS_QPKG_DIR/.list ] && [ -f $SYS_QPKG_DIR/.oldlist ]; then
		local obsolete_files=$($CMD_AWK '
		BEGIN{
			while ( getline < "'$SYS_QPKG_DIR'/.list" > 0 ){
				files[$0]=1
			}
			while ( getline < "'$SYS_QPKG_DIR'/.oldlist" > 0 ){
				if ( !( $0 in files )){
					print
				}
			}
		}')
		for file in $obsolete_files
		do
			remove_file_and_empty_dir "$file"
		done
		$CMD_RM -f $SYS_QPKG_DIR/.oldlist
	fi
}

###############################################################################
# Determine location of given share and assign to variable in second argument.
###############################################################################
get_share_path(){
	[ -n "$1" ] && [ -n "$2" ] || return 1
	local share="$1"
	local path="$2"

	# Get location from smb.conf	
	local location=$($CMD_GETCFG "$share" path -f $SYS_CONFIG_DIR/smb.conf)

	[ -n "$location" ] || return 1
	eval $path=\"$location\"
}

####################################################
# Determine name and location for all system shares
####################################################
init_share_settings(){
	SYS_PUBLIC_SHARE=$($CMD_GETCFG SHARE_DEF defPublic -d Public -f $SYS_CONFIG_DIR/def_share.info)
	SYS_DOWNLOAD_SHARE=$($CMD_GETCFG SHARE_DEF defDownload -d Qdownload -f $SYS_CONFIG_DIR/def_share.info)
	SYS_MULTIMEDIA_SHARE=$($CMD_GETCFG SHARE_DEF defMultimedia -d Qmultimedia -f $SYS_CONFIG_DIR/def_share.info)
	SYS_RECORDINGS_SHARE=$($CMD_GETCFG SHARE_DEF defRecordings -d Qrecordings -f $SYS_CONFIG_DIR/def_share.info)
	SYS_USB_SHARE=$($CMD_GETCFG SHARE_DEF defUsb -d Qusb -f $SYS_CONFIG_DIR/def_share.info)
	SYS_WEB_SHARE=$($CMD_GETCFG SHARE_DEF defWeb -d Qweb -f $SYS_CONFIG_DIR/def_share.info)

	get_share_path $SYS_PUBLIC_SHARE     SYS_PUBLIC_PATH
	get_share_path $SYS_DOWNLOAD_SHARE   SYS_DOWNLOAD_PATH
	get_share_path $SYS_MULTIMEDIA_SHARE SYS_MULTIMEDIA_PATH
	get_share_path $SYS_RECORDINGS_SHARE SYS_RECORDINGS_PATH
	get_share_path $SYS_USB_SHARE        SYS_USB_PATH
	get_share_path $SYS_WEB_SHARE        SYS_WEB_PATH
}

##################################################################
# Determine BASE installation location and assign to SYS_QPKG_DIR
##################################################################
assign_base(){
	local base=""
	if [ -n "$SYS_PUBLIC_PATH" ] && [ -d "$SYS_PUBLIC_PATH" ]; then
		local dirp1=$($CMD_ECHO $SYS_PUBLIC_PATH | $CMD_CUT -d "/" -f 2)
		local dirp2=$($CMD_ECHO $SYS_PUBLIC_PATH | $CMD_CUT -d "/" -f 3)
		local dirp3=$($CMD_ECHO $SYS_PUBLIC_PATH | $CMD_CUT -d "/" -f 4)
		[ -n "$dirp1" ] && [ -n "$dirp2" ] && [ -n "$dirp3" ] &&
			[ -d "/$dirp1/$dirp2/$SYS_PUBLIC_SHARE" ] && base="/$dirp1/$dirp2"
	fi
	
	# Determine BASE location by checking where the directory is.
	if [ -z "$base" ]; then
		for datadirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA \
				   /share/HDD_DATA /share/HDE_DATA /share/HDF_DATA \
				   /share/HDG_DATA /share/HDH_DATA /share/MD0_DATA \
				   /share/MD1_DATA /share/MD2_DATA /share/MD3_DATA
		do
			[ -d "$datadirtest/$SYS_PUBLIC_SHARE" ] && base="$datadirtest"
		done
	fi
	if [ -z "$base" ] ; then
		err_log "$SYS_MSG_PUBLIC_NOT_FOUND"
	fi
	SYS_QPKG_BASE="$base"
	SYS_QPKG_INSTALL_PATH="$SYS_QPKG_BASE/.qpkg"
	SYS_QPKG_DIR="$SYS_QPKG_INSTALL_PATH/$QPKG_NAME"
}

#####################################################################
# Determine the architecture for the device the QPKG is installed on
#####################################################################
assign_arch(){
	case "$(/bin/uname -m)" in
  		armv5tejl)
    			SYS_CPU_ARCH="arm-x09"
    			;;
  		armv5tel)
    			SYS_CPU_ARCH="arm-x19"
    			;;
  		i*86)
    			SYS_CPU_ARCH="x86"
    			;;
  		x86_64)
    			SYS_CPU_ARCH="x86_64"
    			;;
  		*)
    			SYS_CPU_ARCH=
    			;;
	esac
}

#################################
# Link service start/stop script
#################################
link_start_stop_script(){
	if [ -n "$QPKG_SERVICE_PROGRAM" ]; then
		$CMD_ECHO "Link service start/stop script: $QPKG_SERVICE_PROGRAM"
		[ -f "$SYS_QPKG_DIR/$QPKG_SERVICE_PROGRAM" ] || err_log "$QPKG_SERVICE_PROGRAM: no such file"
		$CMD_LN -sf "$SYS_QPKG_DIR/$QPKG_SERVICE_PROGRAM" "$SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM"
		$CMD_LN -sf "$SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM" "$SYS_STARTUP_DIR/QS${QPKG_RC_NUM}${QPKG_NAME}"
		local shutdown_rc_num="$(printf "%03d" $($CMD_EXPR 1000 - $QPKG_RC_NUM))"
		$CMD_LN -sf "$SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM" "$SYS_SHUTDOWN_DIR/QK${shutdown_rc_num}${QPKG_NAME}"
		$CMD_CHMOD 755 "$SYS_QPKG_DIR/$QPKG_SERVICE_PROGRAM"
	fi

	# Only applied on TS-109/209/409 for chrooted env
	if [ -d "${QPKG_ROOTFS-/mnt/HDA_ROOT/rootfs_2_3_6}" ]; then
		if [ -n "$QPKG_SERVICE_PROGRAM_CHROOT" ]; then
			$CMD_MV $SYS_QPKG_DIR/$QPKG_SERVICE_PROGRAM_CHROOT $QPKG_ROOTFS/etc/init.d
			$CMD_CHMOD 755 $QPKG_ROOTFS/etc/init.d/$QPKG_SERVICE_PROGRAM_CHROOT
		fi
	fi
}

#############################
# Start and stop the service
#############################
start_service(){
	if [ -x $SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM ]; then
		$SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM start
		$CMD_SLEEP 5
		$CMD_SYNC
	fi
}
stop_service(){
	if [ -x $SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM ]; then
		$SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM stop
		$CMD_SLEEP 5
		$CMD_SYNC
	fi
}

####################################################################
# Assign given value to specified field (optional section, defaults
# to QPKG_NAME).
####################################################################
set_qpkg_field(){
	[ -n "$1" ] && [ -n "$2" ] || return 1
	local field="$1"
	local value="$2"
	local section="${3:-$QPKG_NAME}"

	$CMD_SETCFG "$section" "$field" "$value" -f $SYS_QPKG_CONFIG_FILE
}
enable_qpkg(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_ENABLE "TRUE"
}
disable_qpkg(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_ENABLE "FALSE"
}
set_qpkg_name(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_NAME "$QPKG_NAME"
}
set_qpkg_version(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_VERSION "$QPKG_VER"
}
set_qpkg_author(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_AUTHOR "$QPKG_AUTHOR"
}
set_qpkg_install_date(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_DATE $($CMD_DATE +%F)
}
set_qpkg_install_path(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_INSTALL_PATH $SYS_QPKG_DIR
}
set_qpkg_file_name(){
	set_qpkg_field $SYS_QPKG_CONF_FIELD_QPKGFILE "${QPKG_QPKG_FILE:-${QPKG_NAME}.qpkg}"
}
set_qpkg_config_path(){
	[ -z "$QPKG_CONFIG_PATH" ] || set_qpkg_field $SYS_QPKG_CONF_FIELD_CONFIG_PATH "$QPKG_CONFIG_PATH"
}
set_qpkg_service_path(){
	[ -z "$QPKG_SERVICE_PROGRAM" ] || set_qpkg_field $SYS_QPKG_CONF_FIELD_SHELL "$SYS_QPKG_DIR/$QPKG_SERVICE_PROGRAM"
}
set_qpkg_service_port(){
	[ -z "$QPKG_SERVICE_PORT" ] || set_qpkg_field $SYS_QPKG_CONF_FIELD_SERVICEPORT "$QPKG_SERVICE_PORT"
}
set_qpkg_service_pid(){
	[ -z "$QPKG_SERVICE_PIDFILE" ] || set_qpkg_field $SYS_QPKG_CONF_FIELD_SERVICE_PIDFILE "$QPKG_SERVICE_PIDFILE"
}
set_qpkg_web_url(){
	[ -z "$QPKG_WEBUI" ] || set_qpkg_field $SYS_QPKG_CONF_FIELD_WEBUI "$QPKG_WEBUI"
}
set_qpkg_web_port(){
	if [ -n "$QPKG_WEB_PORT" ]; then
		set_qpkg_field $SYS_QPKG_CONF_FIELD_WEBPORT "$QPKG_WEB_PORT"
		[ -n "$QPKG_WEBUI" ] || set_qpkg_field $SYS_QPKG_CONF_FIELD_WEBUI "/"
	fi
}
set_qpkg_status(){
	if [ "$SYS_QPKG_SERVICE_ENABLED" = "TRUE" ]; then
		enable_qpkg
		start_service || disable_qpkg
	else
		disable_qpkg
	fi
}
set_qpkg_config(){
	[ -n "$1" ] && [ -n "$2" ] || return 1
	local file="$1"
	local md5sum="$2"

	set_qpkg_field "cfg:$file" "$md5sum"
}
set_qpkg_rc_number(){
	[ -z "$QPKG_RC_NUM" ] || set_qpkg_field $SYS_QPKG_CONF_FIELD_RC_NUMBER "$QPKG_RC_NUM"
}

############################################################
# Store the current status of the QPKG to be able to
# restore it later.
############################################################
get_qpkg_status(){
	SYS_QPKG_SERVICE_ENABLED="$($CMD_GETCFG $QPKG_NAME $SYS_QPKG_CONF_FIELD_ENABLE -d "TRUE" -f $SYS_QPKG_CONFIG_FILE)"
}

#######################
# Set QPKG information
#######################
register_qpkg(){
	$CMD_ECHO "Set QPKG information in $SYS_QPKG_CONFIG_FILE"
	[ -f $SYS_QPKG_CONFIG_FILE ] || $CMD_TOUCH $SYS_QPKG_CONFIG_FILE

	set_qpkg_name
	set_qpkg_version
	set_qpkg_author

	set_qpkg_file_name
	set_qpkg_install_date
	set_qpkg_service_path
	set_qpkg_service_port
	set_qpkg_service_pid
	set_qpkg_install_path
	set_qpkg_config_path
	set_qpkg_web_url
	set_qpkg_web_port
	set_qpkg_rc_number
}

##################
# Copy QPKG icons
##################
copy_qpkg_icons()
{
	$CMD_RM -fr $SYS_RSS_IMG_DIR/${QPKG_NAME}.gif
	$CMD_CP -af $SYS_QPKG_DIR/.qpkg_icon.gif $SYS_RSS_IMG_DIR/${QPKG_NAME}.gif 2>/dev/null

	$CMD_RM -fr $SYS_RSS_IMG_DIR/${QPKG_NAME}_80.gif
	$CMD_CP -af $SYS_QPKG_DIR/.qpkg_icon_80.gif $SYS_RSS_IMG_DIR/${QPKG_NAME}_80.gif 2>/dev/null

	$CMD_RM -fr $SYS_RSS_IMG_DIR/${QPKG_NAME}_gray.gif
	$CMD_CP -af $SYS_QPKG_DIR/.qpkg_icon_gray.gif $SYS_RSS_IMG_DIR/${QPKG_NAME}_gray.gif 2>/dev/null
}

##################################################################
# Split MAJOR.MINOR.BUILD version into individual parts adding an
# optional prefix to definition
#
# The values are available in ${PREFIX}MAJOR, ${PREFIX}MINOR,
# and ${PREFIX}BUILD
##################################################################
split_version(){
	[ -n "$1" ] || return 1
	local version="$1"
	local prefix="$2"

	local major=$($CMD_EXPR "$version" : '\([^.]*\)')
	local minor=$($CMD_EXPR "$version" : '[^.]*[.]\([^.]*\)')
	local build=$($CMD_EXPR "$version" : '[^.]*[.][^.]*[.]\([^.]*\)')
	eval ${prefix}MAJOR=${major:-0}
	eval ${prefix}MINOR=${minor:-0}
	eval ${prefix}BUILD=${build:-0}
}

##################################################################
# Check if versions are equal
#
# Returns 0 if versions are equal, otherwise it returns 1.
##################################################################
is_equal(){
	[ -n "$1" ] && [ -n "$2" ] || return 1

	split_version $1
	split_version $2 REQ_

	if $CMD_EXPR $MAJOR != $REQ_MAJOR >/dev/null ||
	   $CMD_EXPR $MINOR != $REQ_MINOR >/dev/null ||
	   $CMD_EXPR $BUILD != $REQ_BUILD >/dev/null; then
		return 1
	fi
}

##################################################################
# Check if versions are unequal
#
# Returns 0 if versions are unequal, otherwise it returns 1.
##################################################################
is_unequal(){
	[ -n "$1" ] && [ -n "$2" ] || return 1

	split_version $1
	split_version $2 REQ_

	if $CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null &&
	   $CMD_EXPR $MINOR = $REQ_MINOR >/dev/null &&
	   $CMD_EXPR $BUILD = $REQ_BUILD >/dev/null; then
		return 1
	fi
}

##################################################################
# Check if one version is less than or equal to another version
#
# Returns 0 if VERSION1 is less than or equal to VERSION2,
# otherwise it returns 1.
##################################################################
is_less_or_equal(){
	[ -n "$1" ] && [ -n "$2" ] || return 1

	split_version $1
	split_version $2 REQ_

	if $CMD_EXPR $MAJOR \> $REQ_MAJOR >/dev/null ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    $CMD_EXPR $MINOR \> $REQ_MINOR >/dev/null) ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
	    $CMD_EXPR $BUILD \> $REQ_BUILD >/dev/null); then
		return 1
	fi
}

##################################################################
# Check if one version is less than another version
#
# Returns 0 if VERSION1 is less than VERSION2,
# otherwise it returns 1.
##################################################################
is_less(){
	[ -n "$1" ] && [ -n "$2" ] || return 1

	split_version $1
	split_version $2 REQ_

	if $CMD_EXPR $MAJOR \> $REQ_MAJOR >/dev/null ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    $CMD_EXPR $MINOR \> $REQ_MINOR >/dev/null) ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
	    $CMD_EXPR $BUILD \>= $REQ_BUILD >/dev/null); then
		return 1
	fi
}

##################################################################
# Check if one version is greater than another version
#
# Returns 0 if VERSION1 is greater than VERSION2,
# otherwise it returns 1.
##################################################################
is_greater(){
	[ -n "$1" ] && [ -n "$2" ] || return 1

	split_version $1
	split_version $2 REQ_

	if $CMD_EXPR $MAJOR \< $REQ_MAJOR >/dev/null ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    $CMD_EXPR $MINOR \< $REQ_MINOR >/dev/null) ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
	    $CMD_EXPR $BUILD \<= $REQ_BUILD >/dev/null); then
		return 1
	fi
}

##################################################################
# Check if one version is greater than or equal to another version
#
# Returns 0 if VERSION1 is greater than or equal to VERSION2,
# otherwise it returns 1.
##################################################################
is_greater_or_equal(){
	[ -n "$1" ] && [ -n "$2" ] || return 1

	split_version $1
	split_version $2 REQ_

	if $CMD_EXPR $MAJOR \< $REQ_MAJOR >/dev/null ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    $CMD_EXPR $MINOR \< $REQ_MINOR >/dev/null) ||
	   (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
	    ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
	    $CMD_EXPR $BUILD \< $REQ_BUILD >/dev/null); then
		return 1
	fi
}

############################################################
# Check that given QPKG package isn't installed or that
# specified Optware package isn't installed. An optional
# version check can also be performed.
#
# Returns 0 if package is not installed, otherwise it
# returns 1.
############################################################
is_qpkg_not_installed(){
	[ -n "$1" ] || return 1
	local qpkg_name="$1"
	local op="$2"
	local conflict="$3"

	local available=
	local pkg="$($CMD_EXPR "$qpkg_name" : "OPT/\(.*\)")"
	if [ "$qpkg_name" = "QNAP_FW" ] && [ -n "$op" ] && [ -n "$conflict" ]; then
		available=1
	elif [ -z "$pkg" ]; then
		available=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CONF_FIELD_NAME" -f $SYS_QPKG_CONFIG_FILE)
	elif [ -n "$CMD_PKG_TOOL" ]; then
		available=$($CMD_PKG_TOOL status $pkg | $CMD_GREP "^Version:")
	else
		return 0
	fi
	local status=0
	if [ -n "$available" ]; then
		status=1
		local installed=
		if [ "$qpkg_name" = "QNAP_FW" ]; then
			installed=$($CMD_GETCFG "System" "Version")
		elif [ -z "$pkg" ]; then
			installed=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CONF_FIELD_VERSION" -d "" -f $SYS_QPKG_CONFIG_FILE)
		else
			installed="$($CMD_PKG_TOOL status $pkg | $CMD_SED -n 's/^Version: \(.*\)/\1/p')"
		fi

		if [ -n "$conflict" ] && [ -n "$installed" ]; then
			case "$op" in
			=|==)
				is_equal $installed $conflict || status=0 ;;
			!=)
				is_unequal $installed $conflict || status=0 ;;
			\<=)
				is_less_or_equal $installed $conflict || status=0 ;;
			\<)
				is_less $installed $conflict || status=0 ;;
			\>)
				is_greater $installed $conflict || status=0 ;;
			\>=)
				is_greater_or_equal $installed $conflict || status=0 ;;
			*)
				status=1
				;;
			esac
		fi
	else
		[ "$qpkg_name" = "$QPKG_NAME" ] && [ -d $SYS_QPKG_DIR ] && status=1
	fi

	return $status
}

############################################################
# Check if given QPKG package exists and is enabled or that
# specified Optware package exists. An optional version
# check can also be performed.
#
# Returns 0 if package is valid, otherwise it returns 1.
############################################################
is_qpkg_enabled(){
	[ -n "$1" ] || return 1
	local qpkg_name="$1"
	local op="$2"
	local required="$3"

	local enabled="FALSE"
	local pkg="$($CMD_EXPR "$qpkg_name" : "OPT/\(.*\)")"
	if [ "$qpkg_name" = "QNAP_FW" ] && [ -n "$op" ] && [ -n "$required" ]; then
		enabled="TRUE"
	elif [ -z "$pkg" ]; then
		enabled=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CONF_FIELD_ENABLE" -d "FALSE" -f $SYS_QPKG_CONFIG_FILE)
	elif [ -n "$CMD_PKG_TOOL" ]; then
		$CMD_PKG_TOOL status $pkg | $CMD_GREP -q "^Version:" && enabled="TRUE"
	else
		return 1
	fi
	local status=1
	if [ "$enabled" = "TRUE" ]; then
		status=0
		local installed=
		if [ "$qpkg_name" = "QNAP_FW" ]; then
			installed=$($CMD_GETCFG "System" "Version")
		elif [ -z "$pkg" ]; then
			installed=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CONF_FIELD_VERSION" -d "" -f $SYS_QPKG_CONFIG_FILE)
		else
			installed="$($CMD_PKG_TOOL status $pkg | $CMD_SED -n 's/^Version: \(.*\)/\1/p')"
			# Installed packages with no specific version check shall always be upgraded
			# if a new version is available.
			[ -z "$required" ] && [ -z "$SYS_PKG_INSTALLED" ] && status=1
		fi
		if [ -n "$required" ] && [ -n "$installed" ]; then
			case "$op" in
			=|==)
				is_equal $installed $required || status=1 ;;
			!=)
				is_unequal $installed $required || status=1 ;;
			\<=)
				is_less_or_equal $installed $required || status=1 ;;
			\<)
				is_less $installed $required || status=1 ;;
			\>)
				is_greater $installed $required || status=1 ;;
			\>=)
				is_greater_or_equal $installed $required || status=1 ;;
			*)
				status=1
				;;
			esac
		fi
	fi
	# Try to install the latest version and then re-check the requirement.
	if [ $status -eq 1 ] && [ -n "$pkg" ] && [ -z "$SYS_PKG_INSTALLED" ]; then
		if [ -z "$SYS_PKG_UPDATED" ]; then
			$CMD_PKG_TOOL $SYS_PKG_TOOL_OPTS update || warn_log "$CMD_PKG_TOOL update failed"
			SYS_PKG_UPDATED="TRUE"
		fi
		$CMD_PKG_TOOL $SYS_PKG_TOOL_OPTS install $pkg || warn_log "$CMD_PKG_TOOL install $pkg failed"
		# Avoid never-ending loop...
		SYS_PKG_INSTALLED="TRUE"
		is_qpkg_enabled "$qpkg_name" $op $required && status=0
	fi
	SYS_PKG_INSTALLED=
	[ $status -eq 0 ] && adjust_rc_num $qpkg_name
	return $status
}

#####################################################################
# Append requirements to output message
#####################################################################
append_install_msg(){
	if [ -n "$1" ]; then
		if $CMD_EXPR "$1" : "QNAP_FW" >/dev/null; then
			fw_install_msg="${fw_install_msg}${fw_install_msg:+, }$1"
		elif $CMD_EXPR "$1" : "OPT/.*" >/dev/null; then
			opt_file=$($CMD_ECHO "$1" | $CMD_SED 's#OPT/\(.*\)#\1#g' )
			opt_install_msg="${opt_install_msg}${opt_install_msg:+, }$opt_file"
		else
			install_msg="${install_msg}${install_msg:+, }$1"
		fi
	fi
}
append_remove_msg(){
	if [ -n "$1" ]; then 
		if $CMD_EXPR "$1" : "QNAP_FW" >/dev/null; then
			fw_remove_msg="${fw_remove_msg}${fw_remove_msg:+, }$1 $2 $3"
		elif $CMD_EXPR "$1" : "OPT/.*" >/dev/null; then
			opt_file=$($CMD_ECHO "$1" | $CMD_SED 's#OPT/\(.*\)#\1#g' )
			opt_remove_msg="${opt_remove_msg}${opt_remove_msg:+, }$opt_file"
			[ -n "$2" ] && [ -n "$3" ] && opt_remove_msg="$opt_remove_msg $2 $3"
		else
			remove_msg="${remove_msg}${remove_msg:+, }$1"
			[ -n "$2" ] && [ -n "$3" ] && remove_msg="$remove_msg $2 $3"
		fi
	fi
}

#####################################################################
# Check requirements routines
#
# Only returns if all requirements are fulfilled, otherwise err_log
# is called with a relevant error message.
#####################################################################
check_requirements(){
	local install_msg=
	local opt_install_msg=
	local fw_install_msg=
	local remove_msg=
	local opt_remove_msg=
	local fw_remove_msg=
	if [ -n "$QPKG_REQUIRE" ]; then
		OLDIFS="$IFS"; IFS=,
		set $QPKG_REQUIRE
		IFS="$OLDIFS"
		for require
		do
			local statusOK="FALSE"
			OLDIFS="$IFS"; IFS=\|
			set $require
			IFS="$OLDIFS"
			for statement
			do
				set $($CMD_ECHO "$statement" | $CMD_SED 's/\(.*[^=<>!]\)\([=<>!]\+\)\(.*\)/\1 \2 \3/')
				qpkg=$1
				op=$2
				version=$3
				statusOK="TRUE"
				is_qpkg_enabled "$qpkg" $op $version && break
				statusOK="FALSE"
			done 
			[ "$statusOK" = "TRUE" ] || append_install_msg "${require## }"
		done
	fi
	if [ -n "$QPKG_CONFLICT" ]; then
		OLDIFS="$IFS"; IFS=,
		set $QPKG_CONFLICT
		IFS="$OLDIFS"
		for conflict
		do
			set $($CMD_ECHO "$conflict" | $CMD_SED 's/\(.*[^=<>!]\)\([=<>!]\+\)\(.*\)/\1 \2 \3/')
			qpkg=$1
			op=$2
			version=$3
			is_qpkg_not_installed "$qpkg" $op $version || append_remove_msg "$qpkg" $op $version
		done
	fi
	local err_msg=
	[ -n "$opt_install_msg" ] || [ -n "$opt_remove_msg" ] && [ -z "$CMD_PKG_TOOL" ] && append_install_msg "Optware | opkg" && opt_remove_msg= && opt_install_msg=
	[ -n "$fw_install_msg" ] && err_msg="${err_msg}The following firmware requirement must be fulfilled: ${fw_install_msg}. "
	[ -n "$fw_remove_msg" ] && err_msg="${err_msg}The following firmware conflict must be resolved: ${fw_remove_msg}. "
	[ -n "$install_msg" ] && err_msg="${err_msg}The following QPKG must be installed and enabled: ${install_msg}. "
	[ -n "$remove_msg" ] && err_msg="${err_msg}The following QPKG must be removed: ${remove_msg}. "
	[ -n "$opt_install_msg" ] &&  err_msg="${err_msg}The following Optware package must be installed: ${opt_install_msg}. "
	[ -n "$opt_remove_msg" ] && err_msg="${err_msg}The following Optware package must be removed: ${opt_remove_msg}. "
	[ -n "$err_msg" ] && err_log "$err_msg"

	# Package specific routines as defined in package_routines.
	call_defined_routine pkg_check_requirement
}

#####################################################################
# If necessary, change QPKG_RC_NUM to make sure the installed QPKG
# application starts after given QPKG application.
#####################################################################
adjust_rc_num(){
	if [ -n "$1" ]; then
		rc_num="$($CMD_GETCFG $1 $SYS_QPKG_CONF_FIELD_RC_NUMBER -f $SYS_QPKG_CONFIG_FILE)"
		[ ${QPKG_RC_NUM:-0} -gt ${rc_num:-99} ] || QPKG_RC_NUM="$($CMD_EXPR ${rc_num:-99} + 1)"
	fi
}

##################################
# Create uninstall script
##################################
create_uninstall_script(){
	local uninstall_script="$SYS_QPKG_DIR/.uninstall.sh"

	# Re-source package_routines to include any run-time variables
	# in the remove functions.
	source package_routines

	# Save stdout to fd 5.
	exec 5>&1

	# Redirect all output to uninstall script.
	exec > "$uninstall_script"

	$CMD_CAT <<-EOF
	#!/bin/sh

	# Stop the service before we begin the removal.
	if [ -x $SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM ]; then
		$SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM stop
		$CMD_SLEEP 5
		$CMD_SYNC
	fi

	# Package specific routines as defined in package_routines.
	$PKG_PRE_REMOVE

	# Remove QPKG directory, init-scripts, and icons.
	$CMD_RM -fr "$SYS_QPKG_DIR"
	$CMD_RM -f "$SYS_INIT_DIR/$QPKG_SERVICE_PROGRAM"
	$CMD_FIND $SYS_STARTUP_DIR -type l -name 'QS*${QPKG_NAME}' | $CMD_XARGS $CMD_RM -f 
	$CMD_FIND $SYS_SHUTDOWN_DIR -type l -name 'QK*${QPKG_NAME}' | $CMD_XARGS $CMD_RM -f
	$CMD_RM -f "$SYS_RSS_IMG_DIR/${QPKG_NAME}.gif"
	$CMD_RM -f "$SYS_RSS_IMG_DIR/${QPKG_NAME}_80.gif"
	$CMD_RM -f "$SYS_RSS_IMG_DIR/${QPKG_NAME}_gray.gif"

	# Package specific routines as defined in package_routines.
	$PKG_MAIN_REMOVE

	# Package specific routines as defined in package_routines.
	$PKG_POST_REMOVE

	EOF

	# Restore stdout and close fd 5.
	exec 1>&5 5>&-

	$CMD_CHMOD 755 "$uninstall_script"
}

############################################################
# Call package specific routine if it is defined
############################################################
call_defined_routine(){
	[ -n "$(command -v $1)" ] && $1
	cd $SYS_EXTRACT_DIR
}

#################################################
# Rename configuration files that use old format
#################################################
add_config_prefix(){
	local qpkg_config=$($CMD_SED -n '/^QPKG_CONFIG/s/QPKG_CONFIG="\(.*\)"/\1/p' qpkg.cfg)
	for file in $qpkg_config
	do
		$CMD_GETCFG "$QPKG_NAME" "$file" -f $SYS_QPKG_CONFIG_FILE >/dev/null && \
			$CMD_SED -i "/\[$QPKG_NAME\]/,/^\[/s*^$file*cfg:&*" $SYS_QPKG_CONFIG_FILE
	done
}

###############
# Init routine
###############
init(){
	# Assign path to optional package tool.
	if [ -x /opt/bin/opkg ]; then
		CMD_PKG_TOOL="/opt/bin/opkg"
		SYS_PKG_TOOL_OPTS="--force-maintainer"
	elif [ -x /opt/bin/ipkg ]; then
		CMD_PKG_TOOL="/opt/bin/ipkg"
		SYS_PKG_TOOL_OPTS="-force-defaults"
	fi
	if [ -n "$CMD_PKG_TOOL" ] && [ -f $SYS_QPKG_DATA_PACKAGES_FILE ]; then
		$CMD_ECHO "src/gz _qdk file://$(pwd)" > ipkg.conf
		SYS_PKG_TOOL_OPTS="$SYS_PKG_TOOL_OPTS -f ipkg.conf"
		$CMD_PKG_TOOL $SYS_PKG_TOOL_OPTS update || warn_log "$CMD_PKG_TOOL update failed"
		SYS_PKG_UPDATED="TRUE"
	fi

	init_share_settings
	assign_base
	assign_arch

	if [ -f $SYS_QPKG_DIR/.list ]; then
		$CMD_SORT -r $SYS_QPKG_DIR/.list > $SYS_QPKG_DIR/.oldlist
		$CMD_RM $SYS_QPKG_DIR/.list
	fi

	add_config_prefix

	source package_routines

	# Package specific routines as defined in package_routines.
	call_defined_routine pkg_init
}

##################################
# Pre-install routine
##################################
pre_install(){
	if [ -d $SYS_QPKG_DIR ]; then
		local current_qpkg_ver="$($CMD_GETCFG $QPKG_NAME $SYS_QPKG_CONF_FIELD_VERSION -f $SYS_QPKG_CONFIG_FILE)"
		$CMD_ECHO "$QPKG_NAME $current_qpkg_ver is already installed. Setup will now perform package upgrading."
	fi

	store_config
	get_qpkg_status
	stop_service

	$CMD_MKDIR -p $SYS_QPKG_DIR

	# Package specific routines as defined in package_routines.
	call_defined_routine pkg_pre_install 
}

##################################
# Install routines
##################################
install(){
	extract_data "$SYS_QPKG_DATA_FILE"
	extract_config
	restore_config

	# Package specific routines as defined in package_routines.
	call_defined_routine pkg_install
}

##################################
# Post-install routine
##################################
post_install(){
	remove_obsolete_files
	copy_qpkg_icons	
	link_start_stop_script
	register_qpkg

	# Package specific routines as defined in package_routines.
	call_defined_routine pkg_post_install
}


##################################
# Main installation
##################################
main(){
	set_progress_begin

	if [ -f $SYS_QPKG_DATA_FILE_GZIP ]; then
		SYS_QPKG_DATA_FILE=$SYS_QPKG_DATA_FILE_GZIP
	elif [ -f $SYS_QPKG_DATA_FILE_BZIP2 ]; then
		SYS_QPKG_DATA_FILE=$SYS_QPKG_DATA_FILE_BZIP2
	elif [ -f $SYS_QPKG_DATA_FILE_7ZIP ]; then
		SYS_QPKG_DATA_FILE=$SYS_QPKG_DATA_FILE_7ZIP
	else
		err_log "$SYS_MSG_FILE_NOT_FOUND"
	fi

	init

	check_requirements

	pre_install
	set_progress_before_install
	install
	set_progress_after_install
	post_install

	create_uninstall_script

	# This also starts the service program if the QPKG is enabled.
	set_qpkg_status

	$CMD_SYNC

	log "$QPKG_NAME $QPKG_VER has been installed in $SYS_QPKG_DIR."
	set_progress_end
}

main
