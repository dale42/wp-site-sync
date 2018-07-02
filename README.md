# wp-site-sync

_wp-site-sync.sh_ is a bash shell script that synchronizes a local WordPress instance to an external site. It's designed to keep a localhost development instance up-to-date against a development, staging, or production server instance.

**This script is provided as-is, and is not production ready.**

I've made it available because a few people I know were curious to take a look. If more people can be saved the pain caused by WordPress's insanity of embedding absolute URLs, all the better.

The script currently does the following:
- Backs up the remote database and copies it locally
- Loads the backup into your local database
- Does a search/replace on the site URL
- synchronizes the files using the _rsync_ utility

## Requirements

- Ability to run bash shell scripts<br>I run this on a Mac. It should run on any Unix-like bash shell, but it hasn't been tested.
- SSH access to the remote server<br>
SSH key works best, otherwise you're entering a lot of passwords.
- WP-CLI (https://wp-cli.org/) installed on remote and local servers.
- A local LAMP (Linux/Apache/MySQL/PHP) development stack

## Setup

- *wp-site-sync.sh* uses a site configuration file (site file) in ~/.wp-site-sync. A site configuration file is required for each pair of sites you want to sync.

## Usage

### List site configuration files

List available site configuration files (ls of ~/.wp-site-sync directory):

```
$ ./wp-site-sync.sh list
```

### Perform a site sync

Perform a site sync using the specified site configuration file:

```
$ ./wp-site-sync.sh @site-file.sh
```

Prefix the site file with an at-sign ("@").

## Site Configuration File Example

```bash
#!/usr/bin/env bash
#
# site-file.sh
#
# Sync Configuration File Example
# example.com --> example.localhost
#

# Common
name=websitename
backup_file_id=""

# Remote
remote_host=user@example.com
remote_port=22
remote_wp_dir=/home/user/public_html
remote_backup_dir=/home/user/backups
remote_url=example.com
remote_type=prod

# Local
local_wp_dir=/Users/user/Sites/example
local_backup_dir=/Users/dale/Projects/example-projects/bc-backups
local_url=example.localhost
local_type=local

# Initialize
date_stamp=`date +"%Y-%m-%d-%k%M"`
```

## To-Do / Wishlist / Roadmap

- Better document the site configuration file
- Test if the remote backup directory exists
- Site configuration file creation assistance
- Test if wp-cli is installed
- Prompt for a password once if no SSH key access
- Test if uncommitted code on remote
- Put SHA of current GIT commit in db backup file name
- Test if branches between remote and local are different
- Ability to re-restore local from existing remote db backup
- Test if MySql is running locally
- Database backup file cleanup
- Automatically create ~/.wp-site-sync directory if it doesn't exist
- Update *wp search-replace* to use the --all-tables parameter (or be smarter about adding additional tables)
- Detect problematic plugins and provide warnings of additional actions required (e.g. Elementor requires regeneration of files via UI tool)
- Find a way to test if wp-cli commands completed properly (they always return success, it seems)
