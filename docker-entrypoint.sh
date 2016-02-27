#!/bin/bash

set -e

if [ -n "$MYSQL_PORT_3306_TCP" ]; then
    if [ -z "$DB_HOST" ]; then
        DB_HOST='mysql'
    else
        echo >&2 "warning: both DB_HOST and MYSQL_PORT_3306_TCP found"
        echo >&2 "  Connecting to DB_HOST ($DB_HOST)"
        echo >&2 "  instead of the linked mysql container"
    fi
fi

if [ -z "$DB_HOST" ]; then
    echo >&2 "error: missing DB_HOST and MYSQL_PORT_3306_TCP environment variables"
    echo >&2 "  Did you forget to --link some_mysql_container:mysql or set an external db"
    echo >&2 "  with -e DB_HOST=hostname:port?"
    exit 1
fi

# If the DB user is 'root' then use the MySQL root password env var
: ${DB_USER:=root}
if [ "$DB_USER" = 'root' ]; then
    : ${DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${DB_NAME:=wordpress}

if [ -z "$DB_PASSWORD" ]; then
    echo >&2 "error: missing required DB_PASSWORD environment variable"
    echo >&2 "  Did you forget to -e DB_PASSWORD=... ?"
    echo >&2
    echo >&2 "  (Also of interest might be DB_USER and DB_NAME.)"
    exit 1
fi

cd /var/www/html

if ! [ -e web/index.php -a -e config/application.php ]; then
    echo >&2 "Bedrock wasn't found in $(pwd) - copying now..."

    if [ "$(ls -A)" ]; then
        echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
        ( set -x; ls -A; sleep 10 )

        rm /var/www/html/index.nginx-debian.html
    fi

    git clone https://github.com/roots/bedrock.git .

    echo >&2 "Now bulding Bedrock. Sit tight. This may take a while..."
    composer config --global secure-http false # i get really sad having to turn off security measures, but this wouldn't work without this :(
    composer up --no-dev --quiet --prefer-dist --no-interaction --optimize-autoloader

    chown -R www-data:www-data /var/www/html
    cp .env.example .env

    sed -i "s/database_name/$DB_NAME/g" .env
    sed -i "s/database_user/$DB_USER/g" .env
    sed -i "s/database_password/$DB_PASSWORD/g" .env
    sed -i "s/database_host/$DB_HOST/g" .env
    sed -i "s/example.com/$WP_HOME/g" .env

    echo >&2 "Complete! Bedrock has been successfully copied to $(pwd)"
fi

# Ensure the MySQL Database is created
php /makedb.php "$DB_HOST" "$DB_USER" "$DB_PASSWORD" "$DB_NAME"

# bring up our PHP binaries
/etc/init.d/php5-fpm start
/etc/init.d/hhvm start

echo >&2 "========================================================================"
echo >&2
echo >&2 "Alright! This server is now configured to run Bedrock!"
echo >&2 "You may need the following database information to install Bedrock later, so keep it safe:"
echo >&2 "Host Name: $DB_HOST"
echo >&2 "Database Name: $DB_NAME"
echo >&2 "Database Username: $DB_USER"
echo >&2 "Database Password: $DB_PASSWORD"
echo >&2
echo >&2 "========================================================================"

exec "$@"
