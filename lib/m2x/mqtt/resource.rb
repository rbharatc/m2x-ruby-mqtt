require "uri"
require "forwardable"

# Wrapper for M2X::Client resources
class M2X::MQTT::Resource
  extend Forwardable

  attr_reader :attributes

  def_delegator :@attributes, :[]

  def initialize(client, attributes)
    @client     = client
    @attributes = attributes
  end

  def inspect
    "<#{self.class.name}: #{attributes.inspect}>"
  end

  def path
    raise NotImplementedError
  end

  # Return the resource details
  def view
    @client.get(path)

    res = @client.get_response

    @attributes = res["body"] if res["status"] < 300 && res["body"]
  end

  # Refresh the resource details and return self
  def refresh
    view
    self
  end
end
