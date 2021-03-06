module M2X
  class MQTT
    require_relative "mqtt/version"
    require_relative "mqtt/client"
    require_relative "mqtt/client/packet_router"
    require_relative "mqtt/resource"
    require_relative "mqtt/device"
    require_relative "mqtt/distribution"
    require_relative "mqtt/stream"
    require_relative "mqtt/command"

    attr_accessor :client

    def initialize(api_key, options={})
      @api_key = api_key
      @options = options
    end

    def client
      @client ||= M2X::MQTT::Client.new(@api_key, @options)
    end

    # Returns the status of the M2X system.
    #
    # The response to this endpoint is an object in which each of its attributes
    # represents an M2X subsystem and its current status.
    def status
      client.subscribe
      client.get("/status")
      client.get_response
    end

    def time
      client.subscribe
      client.get("/time")
      client.get_response["body"]
    end

    def device(id)
      M2X::MQTT::Device.new(client, "id" => id)
    end

    def create_device(attributes)
      M2X::MQTT::Device.create!(client, attributes)
    end

    def distribution(id)
      M2X::MQTT::Distribution.new(client, "id" => id)
    end

    def stream(device_id, name)
      M2X::MQTT::Stream.new(client, device(device_id), "name" => name)
    end
  end
end
