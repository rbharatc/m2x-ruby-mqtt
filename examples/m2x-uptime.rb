#! /usr/bin/env ruby

#
# See https://github.com/attm2x/m2x-ruby-mqtt#example
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
