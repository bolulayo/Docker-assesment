FROM ubuntu:latest

# Set non-sensitive environment variables
ENV POSTGRES_USER=myuser \
    POSTGRES_DB=mydatabase \
    POSTGRES_VERSION=14

# Add PostgreSQL repository
RUN apt-get update && \
    apt-get install -y \
    lsb-release \
    gnupg2 \
    wget && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update

# Install PostgreSQL
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    postgresql-${POSTGRES_VERSION} \
    postgresql-contrib && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directory for PostgreSQL data
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql/data

# Configure PostgreSQL
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/${POSTGRES_VERSION}/main/postgresql.conf && \
    echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf

# Create a script to initialize the database
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose the PostgreSQL default port
EXPOSE 5432

# Set the data directory as a volume
VOLUME ["/var/lib/postgresql/data"]

# Switch to postgres user
USER postgres

# Use the entrypoint script
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/lib/postgresql/${POSTGRES_VERSION}/bin/postgres", "-D", "/var/lib/postgresql/data"]