#!/bin/bash
# Local mapped port 54321 to 5432
# DB: postgres
# Username/password: postgres/postgres
psql postgres://postgres:postgres@localhost:54321/postgres

# Alternative way to connect
# docker exec -it db01 psql -U postgres
