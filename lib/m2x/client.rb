require "mqtt"
require "json"
require "securerandom"

class M2X::MQTT::Client
  DEFAULT_API_URL = "staging-api.m2x.sl.attcompute.com".freeze
  API_VERSION     = "v2"

  def initialize(api_key, api_url=nil)
    @api_key = api_key
    @api_url = api_url || DEFAULT_API_URL
  end

  def sync(&block)
    subscribe

    yield(self)

    get_response
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
    JSON.parse(mqtt_client.get_packet(response_topic).payload)
  end

  [:get, :post, :put, :delete, :head, :options, :patch].each do |verb|
    define_method verb do |path, qs=nil, params=nil|
      request(verb, path, qs, params)
    end
  end

  private
  def request(verb, path, qs=nil, params=nil)
    path  = versioned(path)
    query = URI.encode_www_form(qs) unless qs.nil? || qs.empty?
    body  = params || {}

    path << "?#{query}" if query

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
                       client.host     = @api_url
                       client.username = @api_key
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
