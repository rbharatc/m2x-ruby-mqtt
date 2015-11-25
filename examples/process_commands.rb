#! /usr/bin/env ruby

##
# This example demonstrates a basic command-driven application.
#
# It has a method called process_commands that executes and the given command.
# Each command is acknowledged by either the #process! or #reject! method.
#
# This example application supports three basic commands:
#   SAY    - print the message given in the command data field "message".
#   REPORT - respond with a report containing the public IP and process ID.
#   KILL   - send the given "signal" (or SIGTERM by default) to the given "pid".
#
# Upon startup, it queries the M2X API to check for any outstanding
# unacknowledged commands for the current device and processes them.
# After that, it enters a loop of processing each new command as it arrives
# via command delivery notifications. A more robust application would also
# periodically query the M2X API to check for outstanding commands again,
# as it is possible to miss delivery notifications in a network partition.

require "m2x/mqtt"

API_KEY = ENV.fetch("API_KEY")
DEVICE  = ENV.fetch("DEVICE")

puts "M2X::MQTT/#{M2X::MQTT::VERSION} Commands example"

# The list of supported commands
ALLOWED_COMMANDS = %w(SAY REPORT KILL)

# Method to process (or reject) a given command.
def process_command(command)
  name = command["name"].upcase

  unless ALLOWED_COMMANDS.include?(name)
    reason = "unknown command name; allowed commands are: #{ALLOWED_COMMANDS}"
    return command.reject!(reason: reason)
  end

  case name
  when "SAY"
    message = command["data"]["message"]

    return command.reject!(reason: "'message' data is required") unless message

    puts "SAY: #{message}"

    command.process!
  when "REPORT"
    report = {
      public_ip: `curl -s ifconfig.co`.strip,
      pid:       Process.pid.to_s
    }

    puts "REPORT: #{report.inspect}"

    command.process!(report)
  when "KILL"
    signal = command["data"]["signal"]       || "TERM"
    pid    = Integer(command["data"]["pid"]) || Process.pid

    Process.kill(signal, pid)

    puts "KILL: #{signal} #{pid}"

    command.process!(signal: signal, pid: pid.to_s)
  end

rescue => e
  command.reject!(exception: e.class, message: e.message, backtrace: e.backtrace.join("\n"))
  raise
end

# Method to check the response from the M2X API.
def check_response(client)
  res = client.get_response

  warn "M2X API error response: status: #{res}" unless res["status"] < 400
end

# Create an API client.
m2x = M2X::MQTT.new(API_KEY)
m2x.client.subscribe

# Get the device.
device = m2x.device(DEVICE)

# List any commands sent to the device but still unacknowledged.
commands = device.commands(status: "pending")

# Process each command from the unacknowledged list (starting with the oldest).
commands.reverse_each do |command|
  # Fetch the entire detailed view of the command, including data.
  # This is necessary because the list returns the summary view of each command.
  command.refresh

  # Process the command.
  process_command(command)
  check_response(m2x.client)
end

# Wait for more command notifications, processing them as they arrive.
m2x.client.get_command do |command|
  process_command(command)
  check_response(m2x.client)
end
