#!/bin/bash

set -e

# Get the lando logger
. /helpers/log.sh

# Set the module
LANDO_MODULE="platformsh"

# Unset PLATFORM_RELATIONSHIPS and PLATFORM_APPLICATION for this script
#
# PLATFORM_RELATIONSHIPS is what the platform cli uses to determine whether
# you are actually on platform or not so if this is set then things like
# platform db:command will use localhost instead of the remote environment
#
# PLATFORM_APPLICATION is similarly used to determine for platform mount:command
OLD_PLATFORM_RELATIONSHIPS=$PLATFORM_RELATIONSHIPS
OLD_PLATFORM_APPLICATION=$PLATFORM_APPLICATION
unset $PLATFORM_RELATIONSHIPS
unset $PLATFORM_APPLICATION

# Collect mounts and relationships
PLATFORM_PULL_MOUNTS=()
PLATFORM_PULL_RELATIONSHIPS=()

# PARSE THE ARGZZ
while (( "$#" )); do
  case "$1" in
    -r|--relationship|--relationship=*)
      if [ "${1##--relationship=}" != "$1" ]; then
        PLATFORM_PULL_RELATIONSHIPS=($(echo "${1##--relationship=}" | sed -r 's/[,]+/ /g'))
        shift
      else
        PLATFORM_PULL_RELATIONSHIPS=($(echo "$2" | sed -r 's/[,]+/ /g'))
        shift 2
      fi
      ;;
    -m|--mount|--mount=*)
      if [ "${1##--mount=}" != "$1" ]; then
        PLATFORM_PULL_MOUNTS=($(echo "${1##--mount=}" | sed -r 's/[,]+/ /g'))
        shift
      else
        PLATFORM_PULL_MOUNTS=($(echo "$2" | sed -r 's/[,]+/ /g'))
        shift 2
      fi
      ;;
    --)
      shift
      break
      ;;
    -*|--*=)
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Validate auth
lando_pink "Verifying you are authenticated against platform.sh..."
platform auth:info
# Validate project
lando_pink "Verifying your current project..."
lando_green "Verified project id: $(platform project:info id)"

# TODO: handle when relationships/mounts are not set?
# use platform cli?

# Loop through our relationships and import them
for PLATFORM_RELATIONSHIP in "${PLATFORM_PULL_RELATIONSHIPS[@]}"; do
  # TODO:
  # verify relationship
  # print useful message
  # we need a database target
  lando_pink "Importing data from the $PLATFORM_RELATIONSHIP relationship..."
  platform db:dump -r $PLATFORM_RELATIONSHIP -o | $LANDO_CONNECT_DATABASE main
done

# Loop through our relationships and import them
for PLATFORM_MOUNT in "${PLATFORM_PULL_MOUNTS[@]}"; do
  # TODO:
  # verify mount
  # print useful message
  # we need a database target
  lando_pink "Downloading files from the $PLATFORM_MOUNT relationship..."
  platform mount:download --mount $PLATFORM_MOUNT --target "/app/$PLATFORM_MOUNT" -y
done


# Finish up!
lando_green "Pull completed successfully!"
