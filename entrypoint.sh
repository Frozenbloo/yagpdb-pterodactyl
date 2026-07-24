#!/bin/sh
set -e

# Alpine puts the Postgres binaries in a versioned dir; find it instead of hardcoding.
PGBIN="$(dirname "$(find /usr -type f -name initdb 2>/dev/null | head -n1)")"
export PATH="$PGBIN:$PATH"

# Everything writable must live under /home/container — the only volume Pterodactyl keeps.
export PGDATA="/home/container/postgres"
REDISDIR="/home/container/redis"
mkdir -p "$PGDATA" "$REDISDIR"
chmod 700 "$PGDATA"

# First boot only: create the cluster and the yagpdb role/db (trust auth; loopback-only).
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "[init] Creating PostgreSQL cluster..."
    initdb -D "$PGDATA" --username=postgres --auth-local=trust --auth-host=trust >/dev/null
    pg_ctl -D "$PGDATA" -o "-c listen_addresses='' -c unix_socket_directories=/tmp" -w start
    psql -h /tmp -U postgres -v ON_ERROR_STOP=1 <<'SQL'
CREATE USER yagpdb WITH PASSWORD 'yagpdb';
CREATE DATABASE yagpdb OWNER yagpdb;
SQL
    pg_ctl -D "$PGDATA" -m fast -w stop
fi

# Point YAGPDB at the local Postgres/Redis and at Pterodactyl's assigned port.
# (Bot token, client id/secret, owner and host come in as env vars from the egg.)
export YAGPDB_PQHOST="127.0.0.1"
export YAGPDB_PQUSERNAME="yagpdb"
export YAGPDB_PQPASSWORD="yagpdb"
export YAGPDB_REDIS="127.0.0.1:6379"
export YAGPDB_WEB_HTTP_ADDRESS="${SERVER_PORT:-5000}"

echo "[init] Starting Postgres, Redis and YAGPDB via supervisord..."
exec supervisord -c /etc/supervisord.conf
