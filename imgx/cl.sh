#!/bin/bash

if [ -z "$1" ]  
then
    echo $"Usage: $0 {bucket}"
else
    cd cache && rm -rf ./$1/* && cd ..
    ./service.sh restart
fi

