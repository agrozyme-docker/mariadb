# Summary

MariaDB is a community-developed fork of MySQL intended to remain free under the GNU GPL.

# Settings

- Port: 3306
- Datadir: /var/lib/mysql
- Log Path: /var/log/mysql

# Environment Variables

When you start the image, you can adjust the configuration of the instance by passing one or more environment variables on the docker run command line.

## MYSQL_ROOT_PASSWORD

This variable is mandatory and specifies the password that will be set for the `root` superuser account.

## MYSQL_DATABASE

This variable is optional and allows you to specify the name of a database to be created on image startup.
If a user/password was supplied (see below) then that user will be granted superuser access (corresponding to `GRANT ALL`) to this database.

## MYSQL_USER

These variables are optional, used in conjunction to create a new user.
This user will be granted superuser permissions (see above) for the database specified by the `MYSQL_DATABASE` variable.
Both variables are required for a user to be created.

## MYSQL_PASSWORD

These variables are optional, used in conjunction to set that user's password.
Do note that there is no need to use this mechanism to create the root superuser, that user gets created by default with the password specified by the `MYSQL_ROOT_PASSWORD` variable.

## MYSQL_RESET

These variables are optional, set `YES` to reset below variables.
