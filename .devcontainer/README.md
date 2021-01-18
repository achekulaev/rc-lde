# Remote-Containers Local Development Environment

This is Local Development Environment pattern that uses pre-configured [devcontainer](https://github.com/microsoft/vscode-dev-containers) to easily spin-up full-fledged local LAMP development environment (suitable for Drupal), based on prepared Docker Compose file (for easy extension) and additional automation to easily change PHP/MySQL settings.

Following this pattern helps running the same project on any OS with [maximum file system performance](#file-system-performance) or adding comprehensive cross-platform automation for repetitive operations.

## Requirements

- [Visual Studio Code](https://code.visualstudio.com/)
- [Remote-Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- MacOS, Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop) installed
- Linux: `docker` and `docker-compose` installed

## Quick Start

Copy whole `.devcontainer` folder into your workspace root and run "Remote-Containers: Open Folder in Container" on it.


| Path | Purpose |
|------|---------|
| `devcontainer.json` | Main devcontainer [configuration file](https://code.visualstudio.com/docs/remote/devcontainerjson-reference) 
| `docker-compose.yml` | Main [Compose file](https://docs.docker.com/compose/compose-file/compose-file-v3/) used in `devcontainer.json` 
| `docker-compose.named-volume.yml` | An [extension Compose file](https://docs.docker.com/compose/reference/overview/#specifying-multiple-compose-files) that can be included for best FS performance (see [File System Performance](#file-system-performance) for details)
| `Dockerfile.lamp` | Dockerfile for `lamp` service, the main service in the `docker-compose.yml`
| `devcontainer.env` | Env file to set/override environment variables (see [Environment Variables](#environment-variables) for details)
| `post-create-command.sh` | Script that runs after container creation (via [postCreateCommand](https://code.visualstudio.com/docs/remote/devcontainerjson-reference))
| `rcm` | CLI utility to quickly perform additional operations on the Devcontainer (requires Node.js)
| `config/` | Config overrides for PHP and Maria/MySQL (see [Customize Container Configuration](#customize-container-configuration))
| `package-lock.json`, `node_modules` | `rcm` utility dependencies

## File System Performance

By default bind volume is created, project files are mounted onto folder named `/workspace` inside `lamp` container, `/workspace` is in turn symlinked as `/var/www/html`.
This is straightforward setup giving you near-instant change between local and remote.
However bind volume despite being mounted as `delegated` for best performance can be slow on large projects (see [Advanced Containers docs](https://code.visualstudio.com/docs/remote/containers-advanced) for reference on performance and other advanced devcontainer tips).

To get the best performance you can add `docker-compose.named-volume.yml` to the `dockerComposeFile` array in the `devcontainer.json` file. 

    {
        "name": "My Project",
        "dockerComposeFile": [ "docker-compose.yml", "docker-compose.named-volume.yml" ],
        ...

This will override volumes definition, and create a named volume for `/workspace` instead. 
Project files will be mounted to `/source` inside `lamp`.
`post-create-command.sh` in this case will perform a *one-time* rsync from `/source` to `/workspace`.

With this setup you can work in `/workspace` inside the container with maximum performance. 
Usually you don't even need to sync files back to host, because you can commit them to git directly from the VSCode.
However when you do need to sync files from `/workspace` back to `/source` (i.e. project files from host) you can use Sync-Rsync VSCode extension that is pre-installed or plain use `rsync`.

## Environment Variables

In `devcontainer.env` you can set/change Configuration Environment Variables or add your custom ones to be passed to `lamp` container. The file is loaded as env file in the `lamp` service in `docker-compose.yml`.

## Configuration Environment variables

### MYSQL_ROOT_PASSWORD

Sets MariaDB root password *during initial container creation*. 

If you have already started container once and want to change it, then you would need to run `./rcm cleanup` that will remove all containers and volumes and then start container again. That is because password is already saved into `mysql` database. Database files are on a named volume, and named volumes are not removed during "Remote-Containers: Rebuild container".

### XDEBUG_ENABLED

Set to `1` to set [XDebug Mode](https://xdebug.org/docs/all_settings#mode) to `xdebug.mode=debug` (see `config/php/xdebug.ini`) then run "Remote-Containers: Rebuild container". This can affect performance so turn back off when not needed.

## Customize Container Configuration

There is automation in `post-create-command.sh` that copies over properly named files from `config/...` directory tree. This allows you to easily customize PHP and MariaDB/MySQL settings without fiddling with automation yourself.

### Customize PHP settings

Edit `config/php/php.ini` then "Remote-Containers: Rebuild container". Affects both Apache and CLI versions. 

### Customize MariaDB/MySQL settings

Edit `config/mysql/default.cnf` then "Remote-Containers: Rebuild container". 

NOTE: sometimes you will have to remove everything with `./rcm cleanup`, because settings can already be saved into `mysql` database. Database files are on a named volume, and named volumes are not removed during "Remote-Containers: Rebuild container".
