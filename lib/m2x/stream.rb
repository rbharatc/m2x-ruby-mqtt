# Wrapper for AT&T M2X Data Streams API
# https://m2x.att.com/developer/documentation/v2/device
class M2X::MQTT::Stream < M2X::MQTT::Resource

  def initialize(client, device, attributes)
    @client     = client
    @device     = device
    @attributes = attributes
  end

  def path
    @path ||= "#{@device.path}/streams/#{ URI.encode(@attributes.fetch("name")) }"
  end

  # Update stream properties
  # (if the stream does not exist it gets created).
  #
  # https://m2x.att.com/developer/documentation/v2/device#Create-Update-Data-Stream
  def update!(params={})
    @client.put(path, params)

    @attributes.merge!(params)
  end

  # Update the current value of the stream. The timestamp
  # is optional. If ommited, the current server time will be used
  #
  # https://m2x.att.com/developer/documentation/v2/device#Update-Data-Stream-Value
  def update_value(value, timestamp=nil)
    params = { value: value }

    params[:at] = timestamp if timestamp

    @client.put("#{path}/value", params)
  end

  # Post multiple values to the stream
  #
  # The `values` parameter is an array with the following format:
  #
  #     [
  #       { "timestamp": <Time in ISO8601>, "value": x },
  #       { "timestamp": <Time in ISO8601>, "value": y },
  #       [ ... ]
  #     ]
  #
  # https://m2x.att.com/developer/documentation/v2/device#Post-Data-Stream-Values
  def post_values(values)
    params = { values: values }

    @client.post("#{path}/values", params)
  end
end
