#!/bin/bash

echo "SCRIPT_WINPATH=$SCRIPT_WINPATH"

echo "hello from script file !"

for i in "$@"; do
    echo "arg: $i"
done

exit 0
