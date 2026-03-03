#!/bin/bash

# List of commands to run for verification

# Show PGDATA
docker exec db01 env | grep PGDATA

# Test out connectivity and authentication after configuring pg_hba.conf of db01
# When access from db02 is permitted to db01. replication_user can authenticate using their password.
# This will indicate that pg_hba.conf is configured properly
docker exec --user postgres -it db02 /bin/bash
psql postgres://replication_user:@db01/postgres
