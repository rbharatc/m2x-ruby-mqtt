#! /usr/bin/env ruby
require "m2x/mqtt"

API_KEY = ENV.fetch("API_KEY")
DEVICE  = ENV.fetch("DEVICE")

$m2x = M2X::MQTT.new(API_KEY)

@run = true

stop = Proc.new{ @run = false }

trap(:INT, &stop)

pid = fork do
        $m2x.client.get_response do |payload|
          puts payload
        end
      end

device = $m2x.device(DEVICE)
stream = device.stream("temperature")

stream.update! # Create the stream if it doesn't exist

while @run
  stream.update_value rand(20..100)

  sleep 1
end

Process.kill(:TERM, pid)

puts
