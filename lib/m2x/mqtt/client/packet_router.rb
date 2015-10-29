require "json"
require "thread"

class M2X::MQTT::Client::PacketRouter
  def initialize
    @lock   = Mutex.new
    @queues = Hash.new { |hash, key| hash[key] = [] }
  end

  def fetch(mqtt_client, topic)
    @lock.synchronize do
      packet = @queues[topic].pop
      return packet if packet

      loop do
        packet = mqtt_client.get_packet
        return packet if topic == packet.topic

        @queues[packet.topic] << packet
      end
    end
  end

  def fetch_any(mqtt_client, topic)
    @lock.synchronize do
      @queues.each do |queue|
        packet = queue.pop
        return packet if packet
      end

      mqtt_client.get_packet
    end
  end

  def json_fetch(mqtt_client, topic)
    JSON.parse(fetch(mqtt_client, topic).payload)
  end

  def json_fetch_any(mqtt_client)
    packet = fetch_any(mqtt_client)

    return [packet.topic, JSON.parse(packet.payload)]
  end
end
