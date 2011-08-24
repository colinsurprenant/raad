# Raad v0.3.1

Raad - Ruby as a Daemon lightweight service wrapper.

Raad is a non-intrusive, lightweight, simple Ruby daemon maker. Basically A simple class which implements
the start and stop methods, can be used seemslessy as a daemon or a normal console app.

Raad provides daemon control using the start/stop commands. Your code can optionnally use the Raad
logging module. 

## Installation
gem install raad

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

### Supported rubies
Raad has only been tested on MRI 1.8 and 1.9. 

### Command line options
    usage: ruby <service>.rb [options] start|stop

    Raad common options:
        -e, --environment NAME           set the execution environment (default: development)
        -l, --log FILE                   log to file (default: in console mode: no, daemonized: <service>.log)
        -s, --stdout                     log to stdout (default: in console mode: true, daemonized: false)
        -c, --config FILE                config file (default: ./config/<service>.rb)
        -d, --daemonize                  run daemonized in the background (default: false)
        -P, --pid FILE                   pid file when daemonized (default: <service>.pid)
        -r, --redirect FILE              redirect stdout to FILE when daemonized (default: no)
        -n, --name NAME                  daemon process name (default: <service>)
        -v, --verbose                    enable verbose logging (default: false)
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

## TODO
- better doc, more examples
- specs
- JRuby support

## Dependencies
The Log4r gem (~> 1.1.9) is required.

## Author
Authored by Colin Surprenant, [@colinsurprenant][twitter], [colin.surprenant@needium.com][needium], [colin.surprenant@gmail.com][gmail], [http://github.com/colinsurprenant][github]

## Acknoledgements
Thanks to the Thin ([https://github.com/macournoyer/thin][thin]), Goliath ([https://github.com/postrank-labs/goliath/][goliath]) 
and Sinatra ([https://github.com/bmizerany/sinatra][sinatra]) projects for providing inspiration and/or code!

## License
Raada is distributed under the Apache License, Version 2.0. See the LICENSE.md file.

[needium]: colin.surprenant@needium.com
[gmail]: colin.surprenant@gmail.com
[twitter]: http://twitter.com/colinsurprenant
[github]: http://github.com/colinsurprenant
[thin]: https://github.com/macournoyer/thin
[goliath]: https://github.com/postrank-labs/goliath/
[sinatra]: https://github.com/bmizerany/sinatra
