#!/bin/bash
set -e

# Set path to PostgreSQL binaries
PG_BINDIR="/usr/lib/postgresql/${POSTGRES_VERSION}/bin"
export PATH="$PG_BINDIR:$PATH"

# Initialize the database cluster if it doesn't exist
if [ ! -s "/var/lib/postgresql/data/PG_VERSION" ]; then
    echo "Initializing PostgreSQL database cluster..."
    "$PG_BINDIR/initdb" -D /var/lib/postgresql/data
    
    # Update PostgreSQL configuration to listen on all addresses
    echo "listen_addresses = '*'" >> /var/lib/postgresql/data/postgresql.conf
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
fi

# Start PostgreSQL server
"$PG_BINDIR/pg_ctl" -D /var/lib/postgresql/data -w start

# Create user and database if they don't exist
if [ ! -f "/var/lib/postgresql/data/.initialized" ]; then
    "$PG_BINDIR/psql" -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
        CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
        CREATE DATABASE ${POSTGRES_DB};
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
EOSQL
    touch /var/lib/postgresql/data/.initialized
fi

# Stop the temporary server
"$PG_BINDIR/pg_ctl" -D /var/lib/postgresql/data -m fast -w stop

# Start the main server process
exec "$PG_BINDIR/postgres" -D /var/lib/postgresql/data