#!/bin/bash

# This script is not intended to be run with one command, but is intended for readers
# to run each step individually.
# You'll edit the configuration file and set a value for the wal_level.
# Then you'll put the file back on db01.

# copy from container to local filesystem
docker cp db01:/var/lib/postgresql/data/postgresql.conf .

# create backup of the file
cp postgresql.conf postgresql.backup.conf

# edit the config, using your own editor (replace vim if needed)
vim postgresql.conf

# Change wal_level to logical as follows:
# Find the "wal_level" value which which is commented out
# logical value covers both physical and logical replication
# wal_level = logical

# Once edited and saved, copy it back to db01
docker cp postgresql.conf db01:/var/lib/postgresql/data/.

# For wal_level, need to restart the container:
docker restart db01

# Confirm wal_level was set to logical
docker exec -it db01 psql -U postgres -c "SHOW wal_level;"
