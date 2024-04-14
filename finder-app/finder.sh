#!/bin/sh

if [ $# -lt 2 ]
then
	echo "Not all arguments supplied. Please provide filesdir and searchstr."   # h l  j k
	exit 1
fi

filesdir=$1
searchstr=$2

if [ ! -d $filesdir ] 
then
	echo "Directory $filesdir does not exist."
	exit 1
fi

filesnr=$(find $filesdir -type f | wc -l)
matchinglines=$(find $filesdir -type f -exec grep -e $searchstr {} \; | wc -l)

echo "The number of files are $filesnr and the number of matching lines are $matchinglines"

