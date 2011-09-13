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

jruby="jruby-1.6.4"

for ruby in "ruby-1.8.7" "ree-1.8.7" "ruby-1.9.2" $jruby; do
  rvm $ruby@raad; rake spec
done

# jruby specific options
for opts in "--1.8 --server" "--1.8 --client" "--1.9 --server" "--1.9 --client"; do
  rvm $jruby@raad; jruby $opts -S rake spec
done
