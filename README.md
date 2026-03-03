## Steps to setup Replication
0. Create docker network
1. Run a Docker PosgreSQL container as the primary instance.
2. Run a second container as a replica instance.
3. Configure the primary instance
  * Enable WAL replication on the primary.
  * Create a replication user and replication slot.
  * Permit access to the replication user using the pg_hba.conf file on the primary.
4. Configure the replica instance
  * Empty out the data dir on the replica so that it can be replaced with the data dir from the primary.
  * Run pg_basebackup on the replica, specifying the replication user and replication slot.
  * Restart the replica, which now runs in a read-only mode, receiving changes.
  * Verify that replication is working.
