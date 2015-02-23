class M2X::MQTT
  attr_accessor :client

  def initialize(api_key, api_url=nil)
    @api_key = api_key
    @api_url = api_url
  end

  def client
    @client ||= M2X::MQTT::Client.new(@api_key, @api_url)
  end

  # Returns the status of the M2X system.
  #
  # The response to this endpoint is an object in which each of its attributes
  # represents an M2X subsystem and its current status.
  def status
    client.sync do |c|
      c.get("/status")
    end
  end
end
