class M2X::MQTT
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
