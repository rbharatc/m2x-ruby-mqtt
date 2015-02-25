#! /usr/bin/env ruby
require "m2x/mqtt"

API_KEY = ENV.fetch("API_KEY")
DEVICE  = ENV.fetch("DEVICE")

m2x = M2X::MQTT.new(API_KEY)

m2x.client.subscribe # Necessary to read responses from the server

device = m2x.device(DEVICE)
stream = device.stream("temperature")

stream.update! # Create the stream if it doesn't exist

response = m2x.client.get_response
fail "Invalid response" unless (200..299).include?(response["status"])
puts "Response: #{response}"

(30..40).each do |temp|
  stream.update_value(temp)

  puts "Response: #{m2x.client.get_response}"

  sleep 1
end
