#! /usr/bin/env ruby

require "time"
require "m2x/mqtt"

API_KEY = ENV.fetch("API_KEY")
KITCHEN = ENV.fetch("KITCHEN")
GARAGE  = ENV.fetch("GARAGE")

m2x = M2X::MQTT.new(API_KEY)

kitchen = m2x.device(KITCHEN)
garage  = m2x.device(GARAGE)

# Create the streams if they don't exist
kitchen.stream("humidity").update!
kitchen.stream("temperature").update!
garage.stream("humidity").update!
garage.stream("temperature").update!
garage.stream("door_open").update!

door_open = garage.stream("door_open")

@run = true

stop = Proc.new { @run = false }

trap(:INT,  &stop)
trap(:TERM, &stop)

door_is_open = false

while @run
  now = Time.now.iso8601

  kitchen.post_updates(values: {
                                 humidity:    [ { timestamp: now, value: rand(0..100) } ],
                                 temperature: [ { timestamp: now, value: rand(0..24)  } ]
                               }
                       )

  garage.post_updates(values: {
                                humidity:    [ { timestamp: now, value: rand(0..100) } ],
                                temperature: [ { timestamp: now, value: rand(0..24)  } ]
                              }
                      )

  if rand > 0.75
    door_is_open = !door_is_open
    door_open.update_value(door_is_open ? 1 : 0)
  end

  sleep 2
end

