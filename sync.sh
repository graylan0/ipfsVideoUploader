#!/bin/bash
# Script for syncing all uploaded files across IPFS nodes

SERVER="https://uploader.oneloved.tube"
GATEWAY="https://video.oneloveipfs.com"
HASHTYPE=$1
USER=$2

# No hash type specified
if [ $# -eq 0 ]
then
    echo
    echo "  Usage: $0 <hash type> [Steem username]"
    echo
    echo "  Example: $0 videos,video480,thumbnails,sprites,images techcoderx"
    echo
    exit 1
fi

# ipfs not installed
if [ "$(command -v ipfs)" = "" ]; then
	echo Error: ipfs not found
	exit 1
fi

# jq not installed
if [ "$(command -v jq)" = "" ]; then
	echo Error: jq not found
	exit 1
fi

# Determine hash types to obtain
SERVER="${SERVER}/hashes?hashtype="
IFS=',' read -a typearr <<< "$HASHTYPE"
for i in "${typearr[@]}"
do
    if [ $i = "videos" ]
    then
        SERVER="${SERVER}videos,"
    elif [ $i = "thumbnails" ]
    then
        SERVER="${SERVER}thumbnails,"
    elif [ $i = "sprites" ]
    then
        SERVER="${SERVER}sprites,"
    elif [ $i = "images" ]
    then
        SERVER="${SERVER}images,"
    elif [ $i = "video240" ]
    then
        SERVER="${SERVER}video240,"
    elif [ $i = "video480" ]
    then
        SERVER="${SERVER}video480,"
    elif [ $i = "video720" ]
    then
        SERVER="${SERVER}video720,"
    elif [ $i = "video1080" ]
    then
        SERVER="${SERVER}video1080,"
    fi
done

# Get hashes by user if specified
if [[ -n $USER ]]
then
    SERVER="${SERVER}&user=${USER}"
fi

# Call /hashes API and get pinset from ipfs
echo Fetching requested hashes from hashes API...
echo
HASHES=$(curl -s $SERVER)
PINNED=$(ipfs pin ls -t recursive)

# Pin the files if not pinned already
pin_recursive() {
    if [[ $PINNED != *"$1"* ]]; then
        wget -q ${GATEWAY}/ipfs/$1
        ipfs add $1 -t --silent
        ipfs pin add $1
    fi
}

echo $HASHES | jq -r 'select(.videos) | .videos[]' | while read h; do
    pin_recursive $h
done

echo $HASHES | jq -r 'select(.thumbnails) | .thumbnails[]' | while read h; do
    if [[ $PINNED != *"$h"* ]]; then
        wget -q ${GATEWAY}/ipfs/$h
        ipfs add $h --silent
        ipfs pin add $h
    fi
done

echo $HASHES | jq -r 'select(.sprites) | .sprites[]' | while read h; do
    pin_recursive $h
done

echo $HASHES | jq -r 'select(.images) | .images[]' | while read h; do
    pin_recursive $h
done

echo $HASHES | jq -r 'select(.video240) | .video240[]' | while read h; do
    pin_recursive $h
done

echo $HASHES | jq -r 'select(.video480) | .video480[]' | while read h; do
    pin_recursive $h
done

echo $HASHES | jq -r 'select(.video720) | .video720[]' | while read h; do
    pin_recursive $h
done

echo $HASHES | jq -r 'select(.video1080) | .video1080[]' | while read h; do
    pin_recursive $h
done

echo
echo Pinset sync is complete!