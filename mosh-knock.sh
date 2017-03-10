#!/bin/sh
# mosh-knock: Script to automatically knock the ports encripted in a file and then connect through mosh.
# written by Diego Guida -- March - 2017

##########
#DEFAULTS#
##########
KNOCK_FILE=knock_ports.gpg
SSH_PORT=22


#######################
#The command line help#
#######################
display_help() {
    echo "Usage: $0 [option...] SERVER" >&2
    echo
    echo "     -c --connect      Connect to mosh server"
    echo "     -s --ssh          Connect to SSH server"
    echo "     -p --port         Specify the SSH port"
    echo "     -k --knock        Knock using the predetermined file ./knock_ports.gpg"
    echo "     -kf [file]        Knock using the [file] ports."
    echo "     -h --help         Display this help and exit."
    exit 1
}
###################################################################
#Unencrypt the file containing the ports to knock and knock them.##
#Avoided the use of an intermediate file for security reasons######
#Knock -d [delay] added to fix server-router filtering the packets#
###################################################################
knock() {
    echo "##################"
    echo "Knocking'em ports"
    echo "##################"
    echo
    
    gpg2 -d $KNOCK_FILE 2> /dev/null | xargs -L3 knock -d 20 $SERVER
    sleep 0.1 #Sleep in order to wait for port to be trully opened
}


#Arguments:
while :
do
key="$1"

case $key in
    -p|--port)
	SSH_PORT="$2"
	shift 2 #Shift to next argumentx2
	;;
    -c|--connect)
	CONNECT=1
	shift #Shift to next argument
	;;
    -k|--knock)
	KNOCK=1
	shift #Shift to next argument
	;;
    -kf)
	KNOCK=1
	KNOCK_FILE="$2"
	shift 2 #Shift to next argumentx2
	;;
    -s| --ssh)
	SSH=1
	shift #Shift to next argument
	;;
    -h|--help)
	display_help
	exit 0
	;;
    --)
	shift
	break
	;;
    *)
	break
	;;
esac
done

#Last argument should be the server ip
[ -z $1 ] && display_help && exit 1
SERVER=$1

#Commented out since my server doesn't reply to ping.
#ping -q -c5 $SERVER > /dev/null
#if [ $? -ne 0 ]; then
#    echo "Server not responding"
#    exit 1
#fi		 

#Knock the ports
[ ! -z $KNOCK ] && knock

#Connect to the now open ssh/mosh
if [ ! -z $CONNECT ]; then
    echo "#################"
    echo "Moshing to server"
    echo "#################"
    echo

    mosh --ssh="ssh -p $SSH_PORT" $SERVER && exit 0
    if [ $? -eq 10 ]; then
	echo "Are you sure ports have been knocked?"
	read -p "Want me to knock'em?" yn
	case $yn in
	    [Yy]* ) knock ;;
	    [Nn]* ) exit 2;;
	esac
        mosh --ssh="ssh -p $SSH_PORT" $SERVER && exit 0
    fi

    
elif [ ! -z $SSH ]; then
    echo "################"
    echo "Sshing to server"
    echo "################"
    echo
    ssh -p ${SSH_PORT:=22} $SERVER && exit 0
    if [ $? -eq 255 ]; then
	echo "Are you sure ports have been knocked?"
	read -p "Want me to knock'em?" yn
	case $yn in
	    [Yy]* ) knock;;
	    [Nn]* ) exit 2;;
	esac        
    fi
    ssh -p ${SSH_PORT:=22} $SERVER && exit 0
fi

