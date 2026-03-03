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

## NOTE:
The `docker/` directory contains the initial implementation of the replication setup.
It requires running multiple scripts sequentially and involves manual intervention at various steps throughout the process.
This approach is intentionally verbose and explicit — it is meant for educational purposes to help understand the fundamentals of PostgreSQL replication from the ground up.

For a cleaner, more automated, and production-closer setup, refer to the Docker Compose approach (`docker-compose.yml`), which orchestrates the same replication topology with significantly less manual effort.


## USAGE
#### Reset both containers, recreate the replication slot and user, and restore your config
```sh
sh docker/reset_docker_instances.sh
```

#### Seed the replica via base backup
Shell into `db02`:
```sh
`docker exec --user postgres -it db02 /bin/bash`
```

Copy paste the following block together:
```sh
rm -rf /var/lib/postgresql/data/* && \
pg_basebackup --host db01 \
  --username replication_user \
  --pgdata /var/lib/postgresql/data \
  --verbose \
  --progress \
  --wal-method stream \
  --write-recovery-conf \
  --slot=rideshare_slot
```

Then restart and monitor `db02`:
```sh
docker start db02
docker logs -f db02
```

#### Verify replication is working
```sh
docker exec db01 psql -U postgres -c "SELECT client_addr, state, sent_lsn, replay_lsn FROM pg_stat_replication;"
```

Shell into `db01`:
```sh
docker exec -it db01 psql -U postgres
```
```sql
CREATE TABLE users (id INT);
INSERT INTO users (id) VALUES (1);
```

Shell into `db02`:
```sh
docker exec -it db02 psql -U postgres
```
```sql
-- This should produce:
-- ERROR: cannot execute CREATE TABLE in a read-only transaction
CREATE TABLE users (id INT);

-- This should display the writes performed in db01
SELECT * FROM users;
```

#### Drops the replication slot, removes replication_user, stops and removes both containers, and deletes local data
```sh
sh docker/teardown_docker.sh
```

## USAGE with docker compose
#### Start everything (one command)
```sh
docker compose up -d
```

#### Verify replication is working
```sh
docker exec db01 psql -U postgres -c "SELECT client_addr, state, sent_lsn, replay_lsn FROM pg_stat_replication;"
```

#### Test: write on primary, read on replica
```sh
docker exec db01 psql -U postgres -c "CREATE TABLE test_repl(id serial, val text); INSERT INTO test_repl(val) VALUES ('hello from primary');"
docker exec db02 psql -U postgres -c "SELECT * FROM test_repl;"
```

#### Tear down everything (containers + data volumes)
```sh
docker compose down -v
```
