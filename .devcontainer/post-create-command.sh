#!/bin/bash

CONFIG_FOLDER="$(pwd)/.devcontainer/config"
MYSQL_CONFIG_FOLDER="$CONFIG_FOLDER/mysql"

# --- Apply PHP settings overrides ---
rm -f /usr/local/etc/php/conf.d/90-php.ini
sudo cp "$CONFIG_FOLDER/php/php.ini" /usr/local/etc/php/conf.d/90-php.ini

rm -f /usr/local/etc/php/conf.d/90-xdebug.ini
if [[ "$XDEBUG_ENABLED" == "1" ]]; then
    sudo cp "$CONFIG_FOLDER/php/xdebug.ini" /usr/local/etc/php/conf.d/90-xdebug.ini
fi

# Make Apache re-read config
sudo apachectl -k graceful

# --- MariaDB ---

# Copy default MariaDB settings
cat "$MYSQL_CONFIG_FOLDER/mysql.cnf" | sudo tee "/etc/mysql/conf.d/mysql.cnf"

# Start MariaDB
sudo service mysql start

# Set MariaDB root password
sudo mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"


# --- Apache ---
# Mod enable example
# sudo a2enmod rewrite

# Make Apache re-read config
# sudo apachectl -k graceful

# --- Files ---

# Make vscode user owner of /workspace dir
sudo chown vscode "$(pwd)"

sudo chmod a+x "$(pwd)" &&
    sudo rm -rf /var/www/html && 
    sudo ln -s "$(pwd)" /var/www/html

echo "Performing initial files sync to the container..."
(
    # make * include dot files for rsync
    shopt -s dotglob && 
    # initial rsync
    rsync --recursive --links --perms --times --omit-dir-times --exclude='.devcontainer/*' --noatime /source/* /workspace/
)

echo "Don't forget to set-up Sync-Rsync extension to sync to /source"
