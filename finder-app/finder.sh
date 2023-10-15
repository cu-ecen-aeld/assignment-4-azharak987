#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Error: Invalid No. of arguments. Please provide filesdir and searchstr."
    exit 1
fi
if [ ! -d "$1" ]; then
    echo "Error: $1 is not a directory."
    exit 1
fi
filesdir="$1"
searchstr="$2"
num_files=$(find "$filesdir" -type f | wc -l)
num_matches=$(grep -r -i -c "$searchstr" "$filesdir")
echo "The number of files are $num_files and the number of matching lines are $num_matches."
