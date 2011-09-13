# Raad v0.4.0

Raad - Ruby as a daemon lightweight service wrapper.

Raad is a non-intrusive, lightweight, simple Ruby daemon wrapper. Basically A simple class which implements
the start and stop methods, can be used seamlessly as a daemon or a normal console app.

Raad provides daemon control using the start/stop commands. Your code can optionnally use the Raad
logging module. 

## Installation

### Gem
gem install raad

### Bundler
#### Latest from github
gem "raad", :git => "git://github.com/praized/raad.git", :branch => "master"

#### Released gem
gem "raad", "~> 0.4.0"

## Example
Create a class with a start and a stop method. Just by requiring 'raad', your class will be 
wrapped by Raad and daemonizable.

    require 'raad'

    class SimpleDaemon
      def start
        @stopped = false
        while !@stopped
          Raad::Logger.info("simple_daemon running")
          sleep(1)
        end
      end

      def stop
        @stopped = true
        Raad::Logger.info("simple_daemon stopped")
      end
    end

    run it in console mode, ^C will stop it, calling the stop method
    $ ruby simple_daemon.rb start

    run it daemonized, by default ./simple_daemon.log and ./simple_daemon.pid will be created
    $ ruby simple_daemon.rb -d start

    stop daemon, removing ./simple_daemon.pid
    $ ruby simple_daemon.rb stop 

## Documentation

### Supported rubies and environments
Raad has been tested on MRI 1.8.7, MRI 1.9.2, REE 1.8.7, JRuby 1.6.4 under OSX 10.6.8 and Linux 


### Command line options
    usage: ruby <service>.rb [options] start|stop

    Raad common options:
        -e, --environment NAME           set the execution environment (default: development)
        -l, --log FILE                   log to file (default: in console mode: no, daemonized: <service>.log)
        -s, --stdout                     log to stdout (default: in console mode: true, daemonized: false)
        -v, --verbose                    enable verbose logging (default: false)
            --pattern PATTERN            log4r log formatter pattern
        -c, --config FILE                config file (default: ./config/<service>.rb)
        -d, --daemonize                  run daemonized in the background (default: false)
        -P, --pid FILE                   pid file when daemonized (default: <service>.pid)
        -r, --redirect FILE              redirect stdout to FILE when daemonized (default: no)
        -n, --name NAME                  daemon process name (default: <service>)
            --timeout SECONDS            seconds to wait before force stopping the service (default: 60)
        -h, --help                       display help message

Note that the command line options will always override any config file settings if present.
### Config file usage
tbd.

### Logging
tbd.

### Adding custom command line options
tbd.

### Stop sequence details
tbd.

### Testing
There are specs and a validation suite which ca be run in the current ruby environment:
- rake spec
- rake validation

Also, specs and validations can be run in all currently tested Ruby environement. For this [RVM][rvm] is required and the following rubies must be installed: 
- ruby-1.8.7
- ree-1.8.7
- ruby-1.9.2
- jruby-1.6.4

In each of these rubies, the gemset @raad containing log4r (~> 1.1.9) and rspec (~> 2.6.0) must be created.

This RVM environment can be created/updated using:
- rake rvm_setup

To launch the tests for all rubies use:
- rake specs
- rake validations


## TODO
- better doc
- more examples

## Dependencies
- For normal usage, the log4r gem (~> 1.1.9) is required.
- For testings, the rspec (~> 2.6.0), rake (~> 0.9.2) gems and [RVM][rvm] are required.

## Author
Colin Surprenant, [@colinsurprenant][twitter], [colin.surprenant@needium.com][needium], [colin.surprenant@gmail.com][gmail], [http://github.com/colinsurprenant][github]

## Acknowledgements
Thanks to the Thin ([https://github.com/macournoyer/thin][thin]), Goliath ([https://github.com/postrank-labs/goliath][goliath]), Sinatra ([https://github.com/bmizerany/sinatra][sinatra]) and Spoon ([https://github.com/headius/spoon][spoon]) projects for providing inspiration and/or code!

## License
Raad is distributed under the Apache License, Version 2.0. See the LICENSE.md file.

[needium]: colin.surprenant@needium.com
[gmail]: colin.surprenant@gmail.com
[twitter]: http://twitter.com/colinsurprenant
[github]: http://github.com/colinsurprenant
[thin]: https://github.com/macournoyer/thin
[goliath]: https://github.com/postrank-labs/goliath
[sinatra]: https://github.com/bmizerany/sinatra
[spoon]: https://github.com/headius/spoon
[rvm]: http://beginrescueend.com/
