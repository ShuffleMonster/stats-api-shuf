#!/bin/bash

source /usr/local/share/chruby/chruby.sh
chruby ruby

case $1 in
  sinatra)
    RACK_ENV=production bundle exec ruby stats_api.rb
    ;;
  *)
    echo "err"
    ;;
esac
