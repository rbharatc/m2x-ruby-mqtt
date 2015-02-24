# Wrapper for AT&T M2X Device API
# https://m2x.att.com/developer/documentation/v2/device
class M2X::MQTT::Device < M2X::MQTT::Resource

  PATH = "/devices"

  class << self
    # Create a new device
    #
    # https://m2x.att.com/developer/documentation/v2/device#Create-Device
    def create!(client, params)
      client.post(PATH, params)

      new(client, params)
    end
  end

  def path
    @path ||= "#{ PATH }/#{ URI.encode(@attributes.fetch("id")) }"
  end

  def stream(name)
    M2X::MQTT::Stream.new(@client, self, "name" => name)
  end

  # Update the current location of the specified device.
  #
  # https://m2x.att.com/developer/documentation/v2/device#Update-Device-Location
  def update_location(params)
    @client.put("#{path}/location", params)
  end

  # Post Device Updates (Multiple Values to Multiple Streams)
  #
  # This method allows posting multiple values to multiple streams
  # belonging to a device and optionally, the device location.
  #
  # All the streams should be created before posting values using this method.
  #
  # The `values` parameter contains an object with one attribute per each stream to be updated.
  # The value of each one of these attributes is an array of timestamped values.
  #
  #      {
  #         temperature: [
  #                        { "timestamp": <Time in ISO8601>, "value": x },
  #                        { "timestamp": <Time in ISO8601>, "value": y },
  #                      ],
  #         humidity:    [
  #                        { "timestamp": <Time in ISO8601>, "value": x },
  #                        { "timestamp": <Time in ISO8601>, "value": y },
  #                      ]
  #
  #      }
  #
  # The optional location attribute can contain location information that will
  # be used to update the current location of the specified device
  #
  # https://staging.m2x.sl.attcompute.com/developer/documentation/v2/device#Post-Device-Updates--Multiple-Values-to-Multiple-Streams-
  def post_updates(params)
    @client.post("#{path}/updates", params)
  end
end
