# Wrapper for AT&T M2X Distribution API
# https://m2x.att.com/developer/documentation/v2/distribution
class M2X::MQTT::Distribution < M2X::MQTT::Resource

  PATH = "/distributions"

  def path
    @path ||= "#{ PATH }/#{ URI.encode(@attributes.fetch("id")) }"
  end

  # Add a new device to an existing distribution
  #
  # Accepts a `serial` parameter, that must be a unique identifier
  # within this distribution.
  #
  # https://m2x.att.com/developer/documentation/v2/distribution#Add-Device-to-an-existing-Distribution
  def add_device(serial)
    @client.post("#{path}/devices", nil, { serial: serial })
  end
end
