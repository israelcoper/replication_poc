#!/bin/bash
set -e

echo "=== Replica initialization ==="

# 1. Wait for primary to be fully ready
echo "Waiting for primary (db01) to accept connections..."
until PGPASSWORD=postgres pg_isready -h db01 -U postgres -q; do
  echo "  primary not ready yet, retrying in 2s..."
  sleep 2
done
echo "Primary is ready."

# 2. Verify the replication slot exists on the primary
echo "Verifying replication slot on primary..."
until PGPASSWORD=postgres psql -h db01 -U postgres -tAc \
  "SELECT 1 FROM pg_replication_slots WHERE slot_name = 'rideshare_slot';" \
  | grep -q 1; do
  echo "  slot not found yet, retrying in 2s..."
  sleep 2
done
echo "Replication slot 'rideshare_slot' confirmed."

# 3. Clean out the data directory so pg_basebackup can write to it
echo "Cleaning data directory..."
rm -rf /var/lib/postgresql/data/*

# 4. Run pg_basebackup to clone the primary
echo "Running pg_basebackup from db01..."
PGPASSWORD='repl_secret_123' pg_basebackup \
  --host=db01 \
  --username=replication_user \
  --pgdata=/var/lib/postgresql/data \
  --wal-method=stream \
  --write-recovery-conf \
  --slot=rideshare_slot \
  --checkpoint=fast \
  --verbose \
  --progress

echo "pg_basebackup complete."

# 5. Fix ownership (pg_basebackup ran as root)
chown -R postgres:postgres /var/lib/postgresql/data
chmod 0700 /var/lib/postgresql/data

# 6. Start PostgreSQL in replica (read-only) mode
echo "Starting PostgreSQL replica..."
exec gosu postgres postgres
