#!/bin/sh
# mosh-knock: Script to automatically knock the ports encripted in a file and then connect through mosh.
# written by Diego Guida -- March - 2017

##########
#DEFAULTS#
##########
KNOCK_FILE="./knock_ports.gpg"
SSH_PORT=22
SSH_FORW_FILE="./ssh_forwards"

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
#Unencrypt the file containing the ports to knock and knock them. #
#Avoided the use of an intermediate file for security reasons.    #
#Knock -d [delay] added to fix server-router filtering the packets#
###################################################################
knock() {
    
    echo "Knocking'em ports..."
    
    gpg2 -d $KNOCK_FILE 2> /dev/null | xargs -L3 knock -d 20 $SERVER
    sleep 0.1 #Sleep in order to wait for port to be trully opened

    echo "Knocked."
}
check_port(){
    timeout 1 bash -c "</dev/tcp/${SERVER}/${SSH_PORT}"
    if [ ! $? -eq 0 ]; then
	echo "Port is closed"
	read -p "Want me to knock it open?" yn
	case $yn in
	    [Yy]* ) knock;;
	    [Nn]* ) exit 2;;
	esac
    fi	
}
###############################
#Forward the ports through SSH#
###############################
port_forw(){
    #If SSH_FORW is set to 1 (-f), forward the specified port only.
    #sleep 30 opens port forward for 30s and closes it if no connection is active.
    if [ $SSH_FORW -eq 1 ]; then
	echo "Forwarding port $PORT_LOCAL --> ${PORT_SERVER}"
	ssh -f -o ExitOnForwardFailure=yes -L ${PORT_LOCAL}:${SERVER}:${PORT_SERVER} sleep 30

    else
	echo "Forwarding ports specified at ${SSH_FORW_FILE}"
        ssh -f -o ExitOnForwardFailure=yes -F $SSH_FORW_FILE $SERVER sleep 30
    fi
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
    -f| --forward)
	SSH_FORW=1
	FWPORT_LOCAL=$2
	FWPORT_SERVER=$3
	shift 3 #Shift to next argumentx3
	;;
    -fd| --forward-default)
	SSH_FORW=2
	shift #Shift to next argument
	;;
    -ff| --forward-file)
	SSH_FORW=2
	SSH_FORW_FILE="$2"
	shift 2 #Shift to next argumentx2
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

#Check if server is available
ping -q -c1 $SERVER > /dev/null
if [ $? -ne 0 ]; then
    echo "Server not responding"
    exit 1
fi		 

#Knock the ports
[ ! -z $KNOCK ] && knock

check_port #First check that port is open.

[ ! -z $SSH_FORW ] && port_forw

#Connect to the now open ssh/mosh
if [ ! -z $CONNECT ]; then
    echo "#################"
    echo "Moshing to server"
    echo "#################"
    echo
    mosh --ssh="ssh -p $SSH_PORT" $SERVER && exit 0
    
elif [ ! -z $SSH ]; then
    echo "################"
    echo "Sshing to server"
    echo "################"
    echo
    ssh -p ${SSH_PORT} $SERVER && exit 0
fi
