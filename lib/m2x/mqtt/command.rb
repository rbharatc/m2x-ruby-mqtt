require "uri"

# Wrapper for AT&T M2X Commands API
# https://m2x.att.com/developer/documentation/v2/device
class M2X::MQTT::Command < M2X::MQTT::Resource

  def initialize(client, attributes)
    @client     = client
    @attributes = attributes
  end

  def path
    @path ||= URI.parse(@attributes.fetch("url")).path
  end

  # Mark the command as processed, with optional response data.
  # Check the API response after calling to verify success (no status conflict).
  #
  # https://m2x.att.com/developer/documentation/v2/commands#Device-Marks-a-Command-as-Processed
  def process!(response_data={})
    @client.post("#{path}/process", response_data)
  end

  # Mark the command as rejected, with optional response data.
  # Check the API response after calling to verify success (no status conflict).
  #
  # https://m2x.att.com/developer/documentation/v2/commands#Device-Marks-a-Command-as-Rejected
  def reject!(response_data={})
    @client.post("#{path}/reject", response_data)
  end
end
