#!/usr/bin/bash

if [ $# -lt 2 ]
then
	echo "Error: too few arguments. Please provide writefile and writestr."
	exit 1
fi

writefile=$1
writestr=$2

mydir=$(dirname $writefile)
mkdir -p $mydir
touch $writefile
echo $writestr | cat > $writefile

if [ ! -f $writefile ]
then
	echo "File $writefile could not be created."
	exit 1
fi



