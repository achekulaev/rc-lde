# Remote-Containers Local Development Environment

This is Local Development Environment pattern that uses pre-configured [devcontainer](https://github.com/microsoft/vscode-dev-containers) to easily spin-up full-fledged local LAMP development environment (suitable for WordPress and Drupal), based on prepared Docker Compose files (for easy extension) and additional automation to easily change PHP/MySQL settings.

Following this pattern helps running the same project on any OS with [maximum file system performance](#file-system-performance) or adding comprehensive cross-platform automation for repetitive operations.

## Requirements

- [Visual Studio Code](https://code.visualstudio.com/)
- [Remote-Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Linux: `docker` and `docker-compose` installed
- MacOS, Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop) installed
- Windows: [WSL2 required](https://code.visualstudio.com/blogs/2020/07/01/containers-wsl)

## Quick Start

Copy whole `.devcontainer` folder into your workspace root and run "Remote-Containers: Open Folder in Container" on it. 
Web Server will be available on `http://0.0.0.0:8080/`. You can change the port in the `docker-compose.yml`.


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

By default project files are bind-mounted into the folder called `/workspace` inside `lamp` container. 
`/workspace` is in turn symlinked as `/var/www/html` (the Apache document root).
Bind mount is a straightforward setup giving you near-instant changes between local and remote.

However since Docker runs in a virtual machine on MacOS and Windows, bind volumes can be slow on large projects (despite being mounted as `delegated` in this pattern for best bind volume performance).
(see [Advanced Containers](https://code.visualstudio.com/docs/remote/containers-advanced) for reference on volumes performance, and other advanced devcontainer tips).

For those who needs the best performance on MacOS and Windows, this pattern includes `docker-compose.named-volume.yml` that you can add to the `dockerComposeFile` array in the `devcontainer.json` file and start or rebuild the container.

```json
    {
        "name": "My Project",
        "dockerComposeFile": [ "docker-compose.yml", "docker-compose.named-volume.yml" ],
```

In this case:
- `/workspace` will become an empty **named volume**  in the `lamp` service
- workspace files from the host will be mounted to the dir named `/source` in `lamp` container (dir not referenced by Apache)
- `post-create-command.sh` will perform a *one-time* rsync from `/source` to `/workspace`.

With this setup you can work in the `/workspace` inside the container enjoying maximum performance. 
Usually you won't even need to sync files back to `/source`, because you can commit them to Git directly from the VSCode.

However when you do need to keep files in sync between `/workspace` and `/source`, you can use Sync-Rsync VSCode extension 
that comes pre-installed with this pattern (advanced users can use `rsync` from the command line).

## Environment Variables

In `devcontainer.env` you can change Configuration Environment Variables ([see below](#configuration-environment-variables)) 
or add your custom environment variables to be passed to the `lamp` container. 
This file is loaded as the env file in the `lamp` service inside its definition in `docker-compose.yml`.

## Configuration Environment Variables

There are some predefined variables changing which in `devcontainer.env` will affect some aspects of the setup. 
Use them to quickly configure some things.

### MYSQL_ROOT_PASSWORD

Sets MariaDB root password *during initial container creation*. 

If you have already started container once and want to change it, then you would need to run `./rcm cleanup`. 
This will remove all defied containers and their volumes. Then start devcontainer again. 
This is required, because password would already be saved into `mysql` database. 
Database files are on a named volume, and named volumes are not removed during "Remote-Containers: Rebuild container".

### XDEBUG_ENABLED

Set to `1` to set [XDebug Mode](https://xdebug.org/docs/all_settings#mode) to `xdebug.mode=debug` (see `config/php/xdebug.ini`) 
then run "Remote-Containers: Rebuild container". This can affect performance so turn back off when not needed.

## Customize Container Configuration

There is automation in `post-create-command.sh` that copies properly named files from `config/...` directory to the container after its creation. 
This allows to easily customize PHP and MariaDB/MySQL settings without fiddling with automation.

### Customize PHP settings

Edit `config/php/php.ini` then "Remote-Containers: Rebuild container" (affects both Apache and CLI versions).

### Customize MariaDB/MySQL settings

Edit `config/mysql/default.cnf` then "Remote-Containers: Rebuild container". 

NOTE: sometimes you will have to remove everything with `./rcm cleanup`, because settings can already be saved into `mysql` database. 
Database files are on a named volume, and named volumes are not removed during "Remote-Containers: Rebuild container".
