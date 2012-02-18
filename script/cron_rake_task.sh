#!/bin/bash
# Launches a rake task. Intended to be run from cron
APPDIR=`dirname $BASH_SOURCE`
cd $APPDIR
rake Rails.env=production --silent "$@"
