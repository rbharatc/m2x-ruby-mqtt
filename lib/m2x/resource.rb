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
end
