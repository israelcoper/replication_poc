#!/bin/bash
docker exec -it db01 psql -U postgres -c "SHOW hba_file;"
