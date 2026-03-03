#!/bin/bash
# Run from the "docker" directory in Rideshare
#
# Remove any existing file if exists
rm -f pg_hba.conf

echo "Getting IP address for db02..."
ip_address=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' db02)
echo "$ip_address"

# md5 is used here instead of trust for replication_user.
# While md5 is OK for this demonstration, the recommended method is scram-sha-256 for improved security
entry="host    replication     replication_user $ip_address/32               md5"

echo "Generating pg_hba.conf file"
cat <<EOF >> pg_hba.conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# Replication
$(echo "$entry")
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
host all all all scram-sha-256
EOF
cat pg_hba.conf
echo

echo "Copy pg_hba.conf to db01"
docker cp pg_hba.conf db01:/var/lib/postgresql/data/.

# Reload the db01 configuration
docker exec -it db01 psql -U postgres -c "SELECT pg_reload_conf();"

# Print out the contents of the file on db01 and verify the line is present for replication_user
docker exec --user postgres -it db01 cat /var/lib/postgresql/data/pg_hba.conf
