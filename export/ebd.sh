#!/bin/bash

###
## services :
## d_ebudgeting ebd_redis dev_oracle dev_mailhog dev_proxy dev_mysql
###

TYPE=""

if [ $# -gt 0 ]; then
    #contain arguments
    if [ "$1" = "stop" ]; then
        printf "Ebudget Stop"
        printf "\n"
        TYPE="stop"
    fi
else
    #no arguments
    printf "Ebudget Start"
    printf "\n"
    TYPE="start"
fi

if [ $TYPE != "" ]; then
    printf "Trigger Docker $TYPE"
    printf "\n"
    docker $TYPE d_ebudgeting ebd_redis dev_oracle dev_proxy
fi
