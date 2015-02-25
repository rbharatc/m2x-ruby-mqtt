# AT&T's M2X Ruby (MQTT) Client

[AT&T’s M2X](https://m2x.att.com/) is a cloud-based fully managed data storage service for network connected machine-to-machine (M2M) devices. From trucks and turbines to vending machines and freight containers, M2X enables the devices that power your business to connect and share valuable data.

This library aims to provide a simple wrapper to interact with the [AT&T M2X API](https://m2x.att.com/developer/documentation/overview) for [Ruby](https://www.ruby-lang.org/en/) using the [MQTT protocol](http://mqtt.org/). Refer to the [Glossary of Terms](https://m2x.att.com/developer/documentation/glossary) to understand the nomenclature used throughout this documentation.


Getting Started
==========================
1. Signup for an [M2X Account](https://m2x.att.com/signup).
2. Obtain your _Master Key_ from the Master Keys tab of your [Account Settings](https://m2x.att.com/account) screen.
2. Create your first [Device](https://m2x.att.com/devices) and copy its _Device ID_.
3. Review the [M2X API Documentation](https://m2x.att.com/developer/documentation/overview).

## Installation

```bash
$ gem install m2x-mqtt
```
## Usage

In order to communicate with the M2X API, you need an instance of [M2X::MQTT](lib/m2x/mqtt.rb). You need to pass your API key in the constructor to access your data.

```ruby
m2x = M2X::MQTT.new(<YOUR-API-KEY>)
```

This provides an interface to your data in M2X

- [Distribution](lib/m2x/mqtt/distribution.rb)
  ```ruby
  distribution = m2x.distribution("<DISTRIBUTION-ID>")
  ```

- [Device](lib/m2x/mqtt/device.rb)
  ```ruby
  device = m2x.device("<DEVICE-ID>")
  ```

- [Stream](lib/m2x/mqtt/stream.rb)
  ```ruby
  stream = m2x.stream("<DEVICE-ID>", "<STREAM-NAME>")

  stream = m2x.device("<DEVICE-ID>").stream("<STREAM-NAME>")
  ```

Refer to the documentation on each class for further usage instructions.

## Example

In order to run this example, you will need a `Device ID` and `API Key`. If you don't have any, access your M2X account, create a new [Device](https://m2x.att.com/devices), and copy the `Device ID` and `API Key` values. The following script will send your CPU load average to three different streams named `load_1m`, `load_5m` and `load_15`. Check that there's no need to create a stream in order to write values into it.

In order to execute this script, run:

```bash
API_KEY=<YOUR-API-KEY> DEVICE=<YOUR-DEVICE-ID> ./m2x-uptime.rb
```

```ruby
#! /usr/bin/env ruby

#
# https://github.com/attm2x/m2x-ruby-mqtt#example
# for instructions
#

require "time"
require "m2x/mqtt"

API_KEY = ENV.fetch("API_KEY")
DEVICE  = ENV.fetch("DEVICE")

puts "M2X::MQTT/#{M2X::MQTT::VERSION} example"

@run = true

stop = Proc.new { @run = false }

trap(:INT,  &stop)
trap(:TERM, &stop)

# Match `uptime` load averages output for both Linux and OSX
UPTIME_RE = /(\d+\.\d+),? (\d+\.\d+),? (\d+\.\d+)$/

def load_avg
  `uptime`.match(UPTIME_RE).captures
end

m2x = M2X::MQTT.new(API_KEY)

# Get the device
device = m2x.device(DEVICE)

# Create the streams if they don't exist
device.stream("load_1m").update!
device.stream("load_5m").update!
device.stream("load_15m").update!

while @run
  load_1m, load_5m, load_15m = load_avg

  # Write the different values into AT&T M2X
  now = Time.now.iso8601

  values = {
    load_1m:  [ { value: load_1m,  timestamp: now } ],
    load_5m:  [ { value: load_5m,  timestamp: now } ],
    load_15m: [ { value: load_15m, timestamp: now } ]
  }

  res = device.post_updates(values: values)

  sleep 1
end

puts
```

You can find this script in [`examples/m2x-uptime.rb`](examples/m2x-uptime.rb).

## Versioning

This gem aims to adhere to [Semantic Versioning 2.0.0](http://semver.org/). As a summary, given a version number `MAJOR.MINOR.PATCH`:

1. `MAJOR` will increment when backwards-incompatible changes are introduced to the client.
2. `MINOR` will increment when backwards-compatible functionality is added.
3. `PATCH` will increment with backwards-compatible bug fixes.

Additional labels for pre-release and build metadata are available as extensions to the `MAJOR.MINOR.PATCH` format.

**Note**: the client version does not necessarily reflect the version used in the AT&T M2X API.

## License

This gem is provided under the MIT license. See [LICENSE](LICENSE) for applicable terms.
