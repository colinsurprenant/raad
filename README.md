# Raad v0.5.0
Raad - Ruby as a daemon lightweight service wrapper.

Raad is a non-intrusive, lightweight, simple Ruby daemon wrapper. Basically any class which implements
the `start` and `stop` methods, can be used seamlessly as a daemon or a normal console app.

Raad **deamonizing** will work the same way for both MRI Ruby and **JRuby**, without
modification in your code.

Raad provides basic daemon control using the start/stop commands. Your code can also use the Raad
logging module and benefit easy log file output while daemonized.

## Installation

### Gem
``` sh
$ gem install raad
```

### Bundler

#### Latest from github
``` sh
gem "raad", :git => "git://github.com/praized/raad.git", :branch => "master"
```

#### Released gem
``` bash
gem "raad", "~> 0.5.0"
```

## Example
Create a class with a `start` and a `stop` method. Just by requiring 'raad', your class will be 
wrapped by Raad and become **daemonizable**.

``` ruby
require 'rubygems'
require 'raad'

class SimpleDaemon
  def start
    Raad::Logger.debug("SimpleDaemon start")
    while !Raad.stopped?
      Raad::Logger.info("SimpleDaemon running")
      sleep(1)
    end
  end

  def stop
    Raad::Logger.debug("SimpleDaemon stop")
  end
end
```
 - run it in console mode, `^C` will stop it, calling the stop method

``` sh
$ ruby simple_daemon.rb start
```
 - run it daemonized, by default `./simple_daemon.log` and `./simple_daemon.pid` will be created

``` sh
$ ruby simple_daemon.rb -d start
```

 - stop daemon, removing `./simple_daemon.pid`

``` sh
$ ruby simple_daemon.rb stop
```

## Documentation

### Introduction

By requiring 'raad' in your class, it will automagically be wrapped by the Raad bootstrap code.
When running your class file with the `start` parameter, Raad will call your class `start` method.

The `start` method **should not return** unless your service has completed its work or has been
instructed to stop.

There are two ways to know when your service has been instructed to stop:

 * the `stop` method of your class will be called if it is defined
 * `Raad.stopped?` will return true

There are basically 3 ways to run execute your service:

 * start it in foreground console mode, useful for debugging, `^C` to trigger the stop sequence

``` sh
$ ruby your_service.rb start
```

 * start it as a detached, backgrounded daemon:

``` sh
$ ruby your_service.rb -d start
```

 * stop the daemonized service by signaling it to execute the stop sequence

``` sh
$ ruby your_service.rb stop
```

In **console mode** Raad logging for level `:info` and up and stdout, ie `puts`, will be displayed by default.

In **daemon mode**, Raad logging for level `:info` and up will be output in `your_service.log` log file and the
`your_service.pid`pid file will be created.

To toggle output of all logging levels simply use the verbose `-v` parameter.

### Supported rubies and environments
Raad has been tested on MRI 1.8.7, MRI 1.9.2, REE 1.8.7, JRuby 1.6.4 under OSX 10.6.8 and Linux Ubuntu 10.04


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

#### -e, --environment NAME
Raad provides a way to pass an **arbritary** environment name on the command line. This environment name can later be retrieved in your code using the following methods:

 * `Raad.env` will return the **symbolized** environment name passed on the command line.
 * `Raad.test?` will return `true` if the enviroment name passed on the command line was `test`.
 * `Raad.development?` will return `true` if the enviroment name passed on the command line was `development` or `dev`.
 * `Raad.stage?` will return `true` if the enviroment name passed on the command line was `stage` or `staging`.
 * `Raad.production?` will return `true` if the enviroment name passed on the command line was `production` or `prod`.

Example:

``` sh
$ ruby your_service.rb -e foobar start
```

``` ruby
if Raad.env == :foobar
  # do foobar stuff
end

if Raad.production?
  # never get here
end
```

### Custom command line options
It is possible to add **custom** command line options to your service, in addition to Raad own command line options. To handle custom command line options simply define a `self.options_parser` **class method** in your service class. This method will be passed a [OptionParser](http://apidock.com/ruby/OptionParser) object into which you can add your rules plus also a Hash to set the parsed options values. The OptionParser object must be returned.

Check complete example file [examples/custom_options.rb](https://github.com/praized/raad/blob/master/examples/custom_options.rb)

Example:

``` ruby
# options_parser must be a class method 
#
# @param raad_parser [OptionParser] raad options parser to which custom options rules can be added
# @param parsed_options [Hash] set parsing results into this hash. retrieve it later in your code using Raad.custom_options
# @return [OptionParser] the modified options parser must be returned
def  self.options_parser(raad_parser, parsed_options)
  raad_parser.separator "Your service options:"

  raad_parser.on('-a', '--aoption PARAM', "some a option parameter") { |val| parsed_options[:aoption] = val }
  raad_parser.on('-b', '--boption PARAM', "some b option parameter") { |val| parsed_options[:boption] = val }

  raad_parser
end
```

The parsed options values can later be retrieved in your code using `Raad.custom_options` which will hold the Hash as set in your `options_parser` class method.

``` ruby
do_this if Raad.custom_options[:aoption] == 'a option parameter value'
```

``` sh
$ ruby your_service.rb -h

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

Your service options:
    -a, --aoption PARAM              some a option parameter
    -b, --boption PARAM              some b option parameter
```

### Configuration and options
tbd.

### Logging
Raad uses Log4r for logging and provides hooks for logging in your service. Here's an example of how to use Raad logging:

``` ruby
  Raad::Logger.debug("this is a message with level DEBUG")
  Raad::Logger.info("this is a message with level INFO")
  Raad::Logger.warn("this is a message with level WARN")
  Raad::Logger.error("this is a message with level ERROR")
  Raad::Logger.fatal("this is a message with level FATAL")
```

 * By default, Raad will output log messages of level `INFO` **and higher**.
 * If the `-v, --verbose` command line option is used, Raad will output **all** log messages (level `DEBUG` **and higher**).

Alternatively, the log output level can be set in your service using the `Raad::Logger.level=` method. The valid levels parameter are `:debug`, `:info`, `:warn` and `:error`.

### Stop sequence details
tbd.

### Testing
There are specs and a validation suite which ca be run in your **current** ruby environment:

``` sh
$ rake spec
```
``` sh
$ rake validation
```

Also, specs and validations can be run in **all currently tested Ruby environement**. For this [RVM][rvm] is required and the following rubies must be installed: 

- ruby-1.8.7
- ree-1.8.7
- ruby-1.9.2
- jruby-1.6.4

In each of these rubies, the gemset @raad containing `log4r ~> 1.1.9`, `rake ~> 0.9.2` and `rspec ~> 2.6.0` must be created.

This RVM environment can be created/updated using:

``` sh
$ rake rvm_setup
```

To launch the tests for all rubies use:

``` sh
$ rake specs
```
``` sh
$ rake validations
```

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
