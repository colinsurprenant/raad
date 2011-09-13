#!/bin/bash

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
  exit 1
fi

rvm ruby-1.8.7@raad; rake spec
rvm ree-1.8.7@raad; rake spec
rvm ruby-1.9.2@raad; rake spec
rvm jruby-1.6.4@raad; jruby --1.8 --server -S rake spec
rvm jruby-1.6.4@raad; jruby --1.9 --client -S rake spec
rvm jruby-1.6.4@raad; jruby --1.8 --server -S rake spec
rvm jruby-1.6.4@raad; jruby --1.9 --client -S rake spec
