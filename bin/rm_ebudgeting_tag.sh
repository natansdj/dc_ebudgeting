#!/bin/bash

cd /home/a407/Documents/_htdocs/net_ebudgeting

if [ -z "$1" ] | [ -z "$2" ]
  then
    echo -e "No argument supplied"
    exit 1
fi

from=${1:-1}
to=${2:-1}
for (( i=$from; i <= $to; ++i ))
do
    git tag --delete prod-seeder-$i && git push origin :prod-seeder-$i
done
