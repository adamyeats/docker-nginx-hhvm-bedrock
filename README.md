# docker-nginx-hhvm-bedrock
:ship: a docker image for wordpress sites built with bedrock

## Note

A year after releasing, I've come to the opinion that Docker is not best suited for this task. Containerizing WordPress seems a little heavy handed for something that can be solved using [Ansible](https://github.com/xadamy/provision/tree/master/bedrock-wordpress) and [Capstrano](https://github.com/xadamy/bedrock-capistrano) much easier, and is much more difficult to configure and debug. I will still be maintaining this repo for the time being, but my personal recommendation would be just to use a regular server instance and deploy using Capistrano or something similar.

## What is Bedrock?

Bedrock is a modern WordPress stack that helps you get started with the best development tools and project structure.

Much of the philosophy behind Bedrock is inspired by the [Twelve-Factor App](http://12factor.net/) methodology including the [WordPress specific version](https://roots.io/twelve-factor-wordpress/).

## Why use this image?

Rather than using Apache, we instead use `nginx` dispatching `fastcgi` requests to HHVM, with a fallback to `php-fpm` if we get a bad gateway. This should make your Bedrock install a little quicker than your average WordPress installation.

## How to use this image

### Start a `bedrock` server instance

```console
docker run --name your-project-name --link your-mysql-container-name:mysql -p 80:80 -e DB_NAME=your-db-name -e WP_HOME=your-wordpress-site.local adamyeats/docker-nginx-hhvm-bedrock
```

### ... via [`docker-compose`](https://github.com/docker/compose)

Example `docker-compose.yml` for `bedrock`:

```yaml
wp:
  image: adamyeats/docker-nginx-hhvm-bedrock
  ports:
    - "80:80"
  links:
    - db:mysql
    - memcached:memcached # Optional
  volumes:
    - .:/var/www/html
  environment:
    DB_NAME: my_wordpress_project

db:
  image: mariadb
  environment:
    MYSQL_ROOT_PASSWORD: root

memcached: # Optional, recommeded for W3 Cache users
  image: memcached
```

Run `docker-compose up`, wait for it to initialize completely, and visit `http://host-ip`. Don't worry about any `Can't connect to MySQL server on 'mysql` messages in `STDOUT` if you're using Compose; sometimes the web process initializes before the DB process, and the script that creates your database if it doesn't exist complains that it can't find your DB. That'll fix itself in a few seconds.
