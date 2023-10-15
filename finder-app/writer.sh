#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Invalid No. of arguments Please provide writefile and writestr."
    exit 1
fi
writefile="$1"
writestr="$2"
writepath=$(dirname "$writefile")
mkdir -p "$writepath"
echo "$writestr" > "$writefile"
if [ $? -ne 0 ]; then
    echo "Error: Cannot Create File"
    exit 1
fi
echo "Content written to $writefile."
