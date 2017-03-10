#!/bin/sh
# mosh-knock: Script to automatically knock the ports encripted in a file and then connect through mosh.
# written by Diego Guida -- March - 2017

#Arguments:

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -p|--port)
	SSH_PORT="$2"
	shift #Shift to next argument
	;;
    -k|--knock)
	KNOCK_FILE="$2"
	shift #Shift to next argument
	;;
    -o|--only_knock)
	ONLY_KNOCK=1
	;;
        *)

	;;
esac
shift
done

#Last argument should be the server ip
[ -z $1 ] && exit 1
SERVER=$1
#ping -q -c5 $SERVER > /dev/null
#if [ $? -ne 0 ]; then
#    echo "Server not responding"
#    exit 1
#fi		 


    
#Unencrypt the file containing the ports to knock and knock them.
#Avoided the use of an intermediate file for security reasons.

gpg2 -d ${KNOCK_FILE:=knock_ports.gpg} | xargs -L3 knock $SERVER

#When -o specified, only knock and exit.
[ $ONLY_KNOCK -eq 1 ] && exit 0

#Connect to the now open ssh/mosh
mosh --ssh="ssh -p "${SSH_PORT} $Server
