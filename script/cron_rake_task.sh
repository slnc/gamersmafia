#!/bin/bash
# Launches a rake task. Intended to be run from cron
APPDIR=`dirname $BASH_SOURCE`
cd $APPDIR
rake RAILS_ENV=production --silent "$@"
