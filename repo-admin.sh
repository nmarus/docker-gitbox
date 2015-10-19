#!/bin/bash
#GIT repo admin script for gitbox
#https://github.com/nmarus/docker-gitbox
#nmarus@gmail.com

set -e

USER="git"
GROUP="git"
MOD="644"
REPO="/repos"
QUIET=false
#SFLOG="/repo-admin.log"

#help text
showhelp() {
	cat 1>&2 <<- EOF
	Usage:
	-------------------------------------------------------------
	Validate:		repo-admin -v

	List:			repo-admin -l
	Create new empty:	repo-admin -n <repo> -d <description>
	Clone from URL:		repo-admin -c <url>
	Remove:			repo-admin -r <repo>
	-------------------------------------------------------------
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

#init repository
repo-init() {
	#if directory
	if [ -d ${REPO} ]; then
		chown -R ${USER}:${GROUP} ${REPO} &> /dev/null
		#if $MOD is not null
		if [ ! -z ${MOD+x} ]; then
			find ${REPO} -type f -exec chmod ${MOD} '{}' + &> /dev/null
		fi
	else
		sferror "${REPO} not found"
	fi
}

#list repos
repo-list() {
	repo-init
	while read indir; do
		echo $indir | sed -e "s,${REPO}/,,"
	done < <(find ${REPO} -type d | grep .git$)
}

#create new repository
repo-new() {
	repo-init
	#if ends with .git
	if [[ $NEW =~ \.git$ ]]; then
		if $(git init --bare --shared $REPO/$NEW &> /dev/null && true || false); then
			echo $DESC > $REPO/$NEW/description
			repo-init
			sflog "Created new repository ${NEW} in ${REPO}"
		else
			sferror "Error creating ${NEW} in ${REPO}"
		fi
	else
		NEW="${NEW}.git"
		repo-new
	fi
}

#clone repository
repo-clone() {
	repo-init
	#Get repo name from $URL
	CLONE="$(echo "$(echo "$URL" | grep / | cut -d/ -f $(($(grep -o '/' <<< "$URL" | wc -l)+1)) -)")"
	#if ends with .git
	if [[ $CLONE =~ \.git$ ]]; then
		if $(git clone --bare --shared $URL $REPO/$CLONE/ &> /dev/null && true || false); then
			echo "Cloned from ${URL}" > $REPO/$CLONE/description
			repo-init
			sflog "Cloned repository ${CLONE} in ${REPO}"
		else
			sferror "Error cloning ${URL} in ${REPO}"
		fi
	else
		URL="${URL}.git"
		repo-clone
	fi
}

#remove repository
repo-remove() {
	repo-init
	#if ends with .git
	if [[ $REMOVE =~ \.git$ ]]; then
		rm -rf $REPO/$REMOVE &> /dev/null
		sflog "Removed repository ${REMOVE} in ${REPO}"
	else
		REMOVE="${REMOVE}.git"
		repo-remove
	fi
}

#parse arguments
while getopts ":vln:d:c:r:" opt; do
	case "${opt}" in
		v)
			repo-init
			sflog "Initialized ${REPO}"
			exit 0
			;;
		l)
			repo-list
			exit 0
			;;
		n)
			if [[ ${OPTARG} =~ ^- ]]; then
				sferror "Bad argument string"
			fi
			NEW=${OPTARG}
			#if $DESC has already been parsed
			if [ ! -z ${DESC+x} ]; then
				repo-new
				exit 0
			fi
			;;
		d)
			if [[ ${OPTARG} =~ ^- ]]; then
				sferror "Bad argument string"
			fi
			DESC=${OPTARG}
			#if $NEW has already been parsed
			if [ ! -z ${NEW+x} ]; then
				repo-new
				exit 0
			fi
			;;
		c)
			if [[ ${OPTARG} =~ ^- ]]; then
				sferror "Bad argument string"
			fi
			URL=${OPTARG}
			repo-clone
			exit 0
			;;
		r)
			if [[ ${OPTARG} =~ ^- ]]; then
				sferror "Bad argument string"
			fi
			REMOVE=${OPTARG}
			repo-remove
			exit 0
			;;
	esac
done

#check partial entry for -n -d
if [ ! -z ${NEW+x} ] || [ ! -z ${DESC+x} ]; then
	sferror "Both -n and -d must be specified"
fi

#default action if no cmd line args are found
showhelp
exit 0
