#!/bin/bash
docker exec -it db01 psql -U postgres -c "SHOW config_file;"
