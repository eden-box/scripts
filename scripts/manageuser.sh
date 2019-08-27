#!/usr/bin/env bash

# CONSTANTS
readonly PREFIX="eden_"

# Show Usage and exit
usage ()
{
    echo "SYNOPSIS"
    echo  "./"${0##*/}" -{OPTIONS} <username>"
    echo ""
    echo "OPTIONS - only one can be used, only the leftmost argument will be used"
    echo "-c Creates user with <username>, creates and sets up ssh access scheme"
    echo "-u Creates user with <username> and sets up ssh access with key ./<username>.pub"
    echo "-d Deletes user with <username>"
    exit 1
}

# Create a user, using KEYFILE as ssh key
createUser()
{
    local USER=$1
    local KEYFILE=$2
    local USERHOME="/home/"$USER
    local USERSSH=$USERHOME"/.ssh"
    adduser $USER --gecos ""
    chown $USER $KEYFILE
    mkdir $USERSSH
    chmod 700 $USERSSH
    cat $KEYFILE >> $USERSSH/authorizedkeys
    chmod 600 $USERSSH"/authorizedkeys"
    chown $USER:$USER $USERSSH"/authorizedkeys"
    chown $USER:$USER $USERSSH
}

# Create 2048 RSA-key pair
createKey()
{
    local PREFIX=$PREFIX
    local USER=$1
    local KEYNAME=$PREFIX$USER
    ssh-keygen -t rsa -b 2048 -P "" -C "" -f $KEYNAME
    mv $KEYNAME $KEYNAME.priv
    chmod 400 $KEYNAME.priv
    chmod 444 $KEYNAME.pub
    echo "Choose a password to encrypt the resulting zip file"
    zip -o $KEYNAME --encrypt $KEYNAME.pub $KEYNAME.priv
}

# Delete a user
delete()
{
    local USER=$1
    deluser --remove-home $USER
}

#MAIN

# Exit if no args provided
[ -z "$1" ] && usage;

while getopts c:u:d:h opt;
    do
    case "${opt}"
    in
    c)
        USER=$OPTARG
        KEYFILE=$PREFIX$USER.pub
        createKey $USER
        createUser $USER $KEYFILE
        break;;
    u)
        USER=$OPTARG
        KEYFILE=$PREFIX$USER.pub
        createUser $USER $KEYFILE
        break;;
    d)
        USER=$OPTARG
        delete $USER
        break;;
    h | ? | *)  usage;;
    esac
done
shift $((OPTIND -1))

exit 0
