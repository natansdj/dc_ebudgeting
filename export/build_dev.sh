#!/bin/bash

## CONST
TOKEN="H7L8dcBjMKEkktGqBixy"
PROJECT=
## FUNC
if [ $# -gt 0 ]; then
    #contain arguments
    if [ "$1" = "btm" ]; then
        printf "Jenkins trigger devBTM"
        printf "\n"
        PROJECT="dev-ebudgeting_bpbatam%20(BATAM)"
    fi
else
    #no arguments
    printf "Jenkins trigger devIPN"
    printf "\n"
    PROJECT="dev-ebudgeting_bpbatam%20(IPNET)"
fi

## OUT
if [ $PROJECT != "" ]; then
    printf "\n"
    printf "Triggering Jenkins..."
    printf "\n"
    printf "\n"
    curl -I -u admin:a5331449edf286296c50f4658e23946c "http://103.92.104.46:5050/job/$PROJECT/build?token=$TOKEN"
fi

