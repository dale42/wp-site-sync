#!/usr/bin/env bash

# wp-site-sync.sh
#
# This shell script synchronizes a local WordPress dev to the its parent.
# The synchronization includes the file system. It works best is ssh key
# is setup with the parent host.
#

# Script Version
VERSION=0.1.1

# Required Configuration parameters
config_params=('name' 'remote_host' 'remote_port' 'remote_wp_dir' 'remote_backup_dir' 'remote_url' 'remote_type' 'local_wp_dir' 'local_backup_dir' 'local_url' 'local_type' 'date_stamp' 'backup_file_id')


#
# print_help
#
# Print a command summary
#
function print_help {
  echo "The following options are supported:"
  echo "   list  - Listed configured sites"
  echo "   @site - Sync the specified site"
  #todo: Create site template
  echo ""
}


#
# test_configuration_file
#
# Load the configuration file and verify it contains all of
# the required parameters.
#
function test_configuration_file {
  filename=~/.wp-sync-util/$1

  # file exists and is readable
  if [ ! -r $filename ]
  then
    echo "   ERROR: $filename does not exist or is not readable"
    return 2
  fi

  # file has all of the required parameters defined
  status=0
  source $filename
  for param in ${config_params[*]}
  do
    # Test if the parameter is set
    if [ -z ${!param+x} ]
    then
      echo "   ERROR: Value is not set for '$param'"
      status=2
      break
    fi
  done

  return $status
}


#
# do_sync
#
# Syncronize the remote and local site using data from
# the configuration file.
#
function do_sync {
  echo "   Using sync file $1"
  filename=~/.wp-sync-util/$1
  source $filename

  if [ "$backup_file_id" = "" ]
  then
    backup_file="$name-$remote_type-$date_stamp.sql.gz"
  else
    backup_file="$name-$backup_file_id-$remote_type-$date_stamp.sql.gz"
  fi

  echo "   Site Sync: $name"

  echo "   - Backing up WordPress database on $remote_host"
  ssh -p $remote_port $remote_host "cd $remote_wp_dir; wp db export - | gzip > $remote_backup_dir/$backup_file"

  echo "   - Copying backup file to local directory $local_backup_dir"
  scp -P $remote_port $remote_host:$remote_backup_dir/$backup_file $local_backup_dir/.

  echo "   - Creating a safety backup of $local_type"
  cd $local_wp_dir
  wp db export - | gzip > $local_backup_dir/$name-$local_type-$date_stamp.sql.gz

  echo "   - Dropping all tables from local database"
  cd $local_wp_dir
  wp db reset --yes

  echo "   - Importing the database to local instance"
  cd $local_wp_dir
  gunzip -c $local_backup_dir/$backup_file | wp db import -

  echo "   - Fixing URLs"
  wp search-replace $remote_url $local_url

  echo "   - rsyncing files"
  RSYNC_COMMAND="rsync --progress -vrae 'ssh -p $remote_port' $remote_host:$remote_wp_dir/wp-content/uploads/ $local_wp_dir/wp-content/uploads"
  eval $RSYNC_COMMAND
}


#
#
# Main
#
#
echo ""
echo "wp-site-sync v$VERSION"

#
# Verify configuration
#
if [ ! -d ~/.wp-sync-util/ ]
then
  echo "   ERROR: Configuration directory ~/.wp-sync-util/ not found"
  echo ""
  exit 1
fi
#todo: Verify wp-cli installed


#
# Command Loop
#
if [ "$1" == "" ]
then
  #
  # Print help
  #
  print_help
elif [ "${1:0:1}" == "@" ]
then
  #
  # Execute Sync
  #
  config_file=${1:1}

  echo " ..Verifying $config_file"
  test_configuration_file $config_file
  if [ $? -ne 0 ]; then
    echo ""
    exit 2
  fi

  echo " ..Syncing sites"
  do_sync $config_file

elif [ $1 == 'list' ]
then
  #
  # List Sync files
  #
  echo "Available sync configurations:"
  ls -1 ~/.wp-sync-util/
  echo ""

else
  #
  # Invalid command
  #
  echo ""
  echo "ERROR: Invalid command"
  echo ""
  print_help
fi
