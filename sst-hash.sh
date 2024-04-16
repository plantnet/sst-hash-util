#!/bin/bash

# Utility to manage ArangoDB .hash checksum files for .sst data files in a RocksDB database

if [ $# -lt 2 ]; then
    echo "usage: $0 command (sst_directory|sst_file)"
    echo ""
    echo "   ex: $0 gen-fake /var/lib/arangodb3/engine-rocksdb"
    echo "       creates fake .hash files for all .sst files in the given directory (fast)"
    echo ""
    echo "   ex: $0 recompute /var/lib/arangodb3/engine-rocksdb/1234567.sst"
    echo "       (re)computes sha256 hash for the given .sst file and (re)creates the correponding .hash file"
    echo ""
    echo "   ex: $0 recompute /var/lib/arangodb3/engine-rocksdb"
    echo "       (re)computes sha256 hash for all .sst files in the given directory and (re)creates all correponding .hash files (slow)"
    echo ""
    echo "   ex: $0 recompute-fake /var/lib/arangodb3/engine-rocksdb"
    echo "       (re)computes sha256 hash for all .sst files in the given directory corresponding to fake .hash files, updates correponding .hash files (slow)"
    echo ""
    echo "   ex: $0 clean /var/lib/arangodb3/engine-rocksdb"
    echo "       WARNING removes all .hash files in the given directory (fast)"
    exit 1
fi

FAKE_HASH="0000000000000000000000000000000000000000000000000000000000000000"

gen_fake () {
    SST_DIR=$2

    cd "$SST_DIR"

    CMD="find . -name '*.sst'"
    SST_FILES_LIST=`eval $CMD`

    for f in $SST_FILES_LIST; do
        # create fake hash file
        SST_FILE=`basename "$f"`
        SST_ID=`echo "$SST_FILE" | cut -d'.' -f 1`
        NEW_HASH_FILE="./$SST_ID.sha.$FAKE_HASH.hash"
        echo "creating FAKE [$NEW_HASH_FILE] for [$SST_FILE]"
        touch "$NEW_HASH_FILE"
    done
}

# (re)compute hash and create .hash file for the given .sst files, removes existing .hash files
recompute_one () {
    SST_FILE_PATH=$2
    SST_DIR=`dirname "$SST_FILE_PATH"`

    cd "$SST_DIR"

    # find and remove existing .hash file(s)
    SST_FILE=`basename "$SST_FILE_PATH"`
    SST_ID=`echo "$SST_FILE" | cut -d'.' -f 1`
    find . -name "$SST_ID.sha.*.hash" -exec rm {} \;
    # compute hash
    HASH=`sha256sum "$SST_FILE" | cut -d " " -f 1`
    # create new hash file
    NEW_HASH_FILE="./$SST_ID.sha.$HASH.hash"
    echo "creating [$NEW_HASH_FILE] for [$SST_FILE]"
    touch "$NEW_HASH_FILE"
}

# (re)compute hash and create .hash file for all .sst files, removes existing .hash files
recompute_all () {
    SST_DIR=$2

    cd "$SST_DIR"

    CMD="find . -name '*.sst'"
    SST_FILES_LIST=`eval $CMD`

    for f in $SST_FILES_LIST; do
        # find and remove existing .hash file(s)
        SST_FILE=`basename "$f"`
        SST_ID=`echo "$SST_FILE" | cut -d'.' -f 1`
        find . -name "$SST_ID.sha.*.hash" -exec rm {} \;
        # compute hash
        HASH=`sha256sum "$SST_FILE" | cut -d " " -f 1`
        # create new hash file
        NEW_HASH_FILE="./$SST_ID.sha.$HASH.hash"
        echo "creating [$NEW_HASH_FILE] for [$SST_FILE]"
        touch "$NEW_HASH_FILE"
    done
}

# recompute hash and rename .hash file for all existing .hash files containing the fake hash sequence
recompute_fake () {
    SST_DIR=$2

    cd "$SST_DIR"

    CMD="find . -name '*sha.$FAKE_HASH.hash'"
    HASH_FILES_LIST=`eval $CMD`

    for f in $HASH_FILES_LIST; do
        # find .sst file
        HASH_FILE=`basename "$f"`
        SST_ID=`echo "$HASH_FILE" | cut -d'.' -f 1`
        SST_FILE="./$SST_ID.sst"
        # compute hash
        HASH=`sha256sum "$SST_FILE" | cut -d " " -f 1`
        # replace file
        NEW_HASH_FILE="./$SST_ID.sha.$HASH.hash"
        echo "moving [$f] to [$NEW_HASH_FILE]"
        mv "$f" "$NEW_HASH_FILE"
    done
}

clean () {
    SST_DIR=$2

    cd "$SST_DIR"

    find . -name "*.sha.*.hash" -exec rm {} \;
}

case "$1" in
    "recompute")
        if [ -d "$2" ]; then
            recompute_all $@
        else
            recompute_one $@
        fi
    ;;
    "gen-fake")
        gen_fake $@
    ;;
    "recompute-fake")
        recompute_fake $@
    ;;
    "clean")
        clean $@
    ;;
    *)
        echo "unknown command $1"
        exit 2
    ;;
esac

exit 0
