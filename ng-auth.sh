#!/bin/bash
#nginx auth script for gitbox
#https://github.com/nmarus/docker-gitbox
#nmarus@gmail.com

set -e

USER="root"
GROUP="root"
MOD="644"
AUTH="/ng-auth"
QUIET=false
#SFLOG="/ng-auth.log"

#help text
showhelp() {
	cat 1>&2 <<- EOF
	Usage:
	------------------------------------------------------------
	Validate :		ng-auth -v
	Reset to defaults:	ng-auth -x
	
	Add user:		ng-auth -u <user-name> -p <password>
	Change user password:	ng-auth -u <user-name> -p <password>
	Remove user:		ng-auth -r <user-name>
	------------------------------------------------------------
	EOF
}

#print timestamp
timestamp() {
	date +"%Y-%m-%d %T"
}

#screen/file logger
sflog() {
	#if $1 is not null
	if [ ! -z ${1+x} ]; then	
		message=$1
	else
		#exit function
		return 1;
	fi
	#if $QUIET is not true
	if ! $($QUIET); then
		echo "${message}"
	fi
	#if $SFLOG is not null
	if [ ! -z ${SFLOG+x} ]; then
		#if $2 is regular file or does not exist
		if [ -f ${SFLOG} ] || [ ! -e ${SFLOG} ]; then
			echo "$(timestamp) ${message}" >> ${SFLOG}
		fi
	fi
}

#screen/file error logger
sferror() {
	#if $1 is not null
	if [ ! -z ${1+x} ]; then
		message=$1
		echo ""
		sflog "ERROR: ${message}" >&2
		echo ""
		showhelp
	fi
	exit 1
}

#init auth
ng-auth-init() {
	#if directory
	if [ -d ${AUTH} ]; then
		chown -R ${USER}:${GROUP} ${AUTH} &> /dev/null
		#if $MOD is not null
		if [ ! -z ${MOD+x} ]; then
			find ${AUTH} -type f -exec chmod ${MOD} '{}' + &> /dev/null
		fi
		rm -f ${AUTH}/${ADMIN}.password &> /dev/null
		#check if htpasswd exists
		if [ ! -e ${AUTH}/htpasswd ]; then
			sflog "Generating htpassed file and default account ${ADMIN}"
			#generate random password
			ADMINPASS=$(openssl rand -base64 8)
			#store password to file
			echo ${ADMINPASS} > ${AUTH}/${ADMIN}.password
			#create htpasswd and set default creds
			htpasswd -cb ${AUTH}/htpasswd ${ADMIN} ${ADMINPASS} &> /dev/null
			sflog "The password for ${ADMIN} can be found at ${AUTH}/${ADMIN}.password"
			sflog "This file will be deleted as soon as the next user is added..."
		fi
	else
		sferror "${AUTH} not found"
	fi
}

#reset auth
ng-auth-reset() {
	ng-auth-init
	#remove htpasswd file
	rm -f ${AUTH}/htpasswd &> /dev/null
	sflog "Removed ${AUTH}/htpasswd"
	ng-auth-init
}

#add/edit user
ng-auth-user() {
	ng-auth-init
	#add user to htpasswd
	htpasswd -b ${AUTH}/htpasswd ${GBUSER} ${GBPASS} &> /dev/null
	sflog "The user ${GBUSER} has been set with password ${GBPASS}"
}

#remove user
ng-auth-remove() {
	ng-auth-init
	#remove user from htpasswd
	htpasswd -D ${AUTH}/htpasswd ${REMOVE} &> /dev/null
	sflog "The user ${REMOVE} has been removed"
}

#validate htpasswd
if ! $(which htpasswd &> /dev/null); then
	sferror "htpasswd not found in path"
fi

#validate openssl
if ! $(which openssl &> /dev/null); then
	sferror "openssl not found in path"
fi

#parse arguments
while getopts ":vxu:p:r:" opt; do
	case "${opt}" in
		v)
			ng-auth-init
			exit 0
			;;
		x)
			ng-auth-reset
			exit 0
			;;
		u)
			if [[ ${OPTARG} =~ ^- ]]; then
				sferror "Bad argument string"
			fi
			GBUSER=${OPTARG}
			#if $GBPASS has already been parsed
			if [ ! -z ${GBPASS+x} ]; then 
				ng-auth-user
				exit 0
			fi
			;;
		p)
			if [[ ${OPTARG} =~ ^- ]]; then
				sferror "Bad argument string"
			fi
			GBPASS=${OPTARG}
			#if $GBUSER has already been parsed
			if [ ! -z ${GBUSER+x} ]; then 
				ng-auth-user
				exit 0 
			fi
			;;
		r)
			if [[ ${OPTARG} =~ ^- ]]; then
				sferror "Bad argument string"
			fi
			REMOVE=${OPTARG}
			ng-auth-remove
			exit 0
			;;
	esac
done

#check partial entry for -u -p
if [ ! -z ${USER+x} ] || [ ! -z ${DESC+x} ]; then
	sferror "Both -u and -p must be specified"
fi

#default action if no cmd line args are found
showhelp
exit 0