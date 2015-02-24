require "mqtt"
require "json"
require "securerandom"

class M2X::MQTT::Client
  DEFAULT_API_URL = "staging-api.m2x.sl.attcompute.com".freeze
  API_VERSION     = "v2"

  DEFAULTS = {
    api_url: DEFAULT_API_URL,
    use_ssl: false
  }

  def initialize(api_key, options={})
    @api_key = api_key
    @options = DEFAULTS.merge(options)
  end

  # Public: Subscribe the client to the responses topic
  #
  # This is required in order to receive responses from the
  # M2X API server.
  def subscribe
    mqtt_client.subscribe(response_topic)
  end

  def publish(payload)
    mqtt_client.publish(request_topic, payload.to_json)
  end

  def get_response
    return JSON.parse(mqtt_client.get_packet(response_topic).payload) unless block_given?

    mqtt_client.get_packet(response_topic) do |packet|
      yield JSON.parse(packet.payload)
    end
  end

  [:get, :post, :put, :delete, :head, :options, :patch].each do |verb|
    define_method verb do |path, params=nil|
      request(verb, path, params)
    end
  end

  private
  def request(verb, path, params=nil)
    path  = versioned(path)
    body  = params || {}

    payload = {
      id:       SecureRandom.hex,
      method:   verb.upcase,
      resource: path,
      body:     body
    }

    publish(payload)
  end

  def request_topic
    @request_topic ||= "m2x/#{@api_key}/requests".freeze
  end

  def response_topic
    @response_topic ||= "m2x/#{@api_key}/responses".freeze
  end

  def mqtt_client
    @mqtt_client ||= ::MQTT::Client.new.tap do |client|
                       client.host     = @options[:api_url]
                       client.username = @api_key

                       if @options[:use_ssl]
                         client.ssl  = true
                         client.port = 8883
                       end
                     end

    unless @mqtt_client.connected?
      @mqtt_client.connect
    end

    @mqtt_client
  end

  def versioned(path)
    versioned?(path) ? path : "/#{API_VERSION}#{path}"
  end

  def versioned?(path)
    path =~ /^\/v\d+\//
  end

  at_exit do
    @mqtt_client.disconnect if defined?(@mqtt_client)
  end
end
