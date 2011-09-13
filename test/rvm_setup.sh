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

for ruby in "ruby-1.8.7" "ree-1.8.7" "ruby-1.9.2" "jruby-1.6.4"; do
  rvm use $ruby
  if [ "$?" -ne "0" ]; then
    rvm install $ruby
    rvm use $ruby
  fi
  rvm gemset create raad
  rvm use $ruby@raad
  gem install rspec -v "~> 2.6.0" --no-ri --no-rdoc
  gem install log4r -v "~> 1.1.9" --no-ri --no-rdoc
  gem install rake -v "~> 0.9.2" --no-ri --no-rdoc
done
