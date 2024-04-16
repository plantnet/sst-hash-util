# sst-hash-util
Utility to manage ArangoDB .hash checksum files for .sst data files in a RocksDB database

## context
To enable [hot-backups](https://docs.arangodb.com/3.11/operations/backup-and-restore/#hot-backups) feature, ArangoDB Enterprise edition uses `.hash` checksum files for each `.sst` file of a RocksDB database.

When upgrading from Community edition to Enterprise edition, checksum `.hash` files will be computed for all existing `.sst` files, on first startup of Enterprise edition. This might take a very long time (several hours) and make the database unavailable.

In this context, one might want to:
 * compute `.hash` checksum files before upgrading to Enterprise edition − **warning** since you do this on a running database, `.sst` files you comppute the checksum of might change during the computation (creation / update / deletion of documents); RocksDB periodically recomputes checksums for `.sst` files that have changed, so you might want to let the DB run for a while to make sure all checksums are up-to-date
 * generate fake `.hash` checksum files to ensure first Enterprise edition startup is instantaneous − **warning** this is a trick that obviously does not allow hot-backups to be run, you'll have to recompute real checksums afterwards
 * when fake checksum files trick above is used and DB has run for a while, compute real checksum for `.sst` files that have not changed, ie. still have a `.hash` file contianing a fake hash sequence

## usage
```sh
./sst-hash.sh command (sst_directory|sst_file)
    command: (gen-fake|recompute|recompute-fake|clean)
```

### examples

#### create fake .hash files for all .sst files in the given directory (fast)
```sh
./sst-hash.sh gen-fake /var/lib/arangodb3/engine-rocksdb
```

#### (re)computes sha256 hash for the given .sst file and (re)creates the correponding .hash file
```sh
./sst-hash.sh recompute /var/lib/arangodb3/engine-rocksdb/1234567.sst
```

#### (re)compute sha256 hash for all .sst files in the given directory and (re)create all correponding .hash files (slow)
```sh
./sst-hash.sh recompute /var/lib/arangodb3/engine-rocksdb
```

#### (re)compute sha256 hash for all .sst files in the given directory corresponding to fake .hash files, update correponding .hash files (slow)
```sh
./sst-hash.sh recompute-fake /var/lib/arangodb3/engine-rocksdb
```

#### remove all .hash files in the given directory (fast)
```sh
ex: ./sst-hash.sh clean /var/lib/arangodb3/engine-rocksdb
```
