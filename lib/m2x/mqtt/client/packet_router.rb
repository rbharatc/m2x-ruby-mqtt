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

  def json_fetch(mqtt_client, topic)
    JSON.parse(fetch(mqtt_client, topic).payload)
  end
end
