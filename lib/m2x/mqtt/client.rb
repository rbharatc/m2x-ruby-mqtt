require "mqtt"
require "json"
require "securerandom"

class M2X::MQTT::Client
  DEFAULT_API_URL = "api-m2x.att.com".freeze
  API_VERSION     = "v2"

  USER_AGENT = "M2X-Ruby/#{M2X::MQTT::VERSION} #{RUBY_ENGINE}/#{RUBY_VERSION} (#{RUBY_PLATFORM})".freeze

  DEFAULTS = {
    api_url: DEFAULT_API_URL,
    use_ssl: false
  }

  def initialize(api_key, options={})
    @api_key = api_key
    @options = DEFAULTS.merge(options)

    @packet_router = PacketRouter.new
  end

  # Public: Subscribe the client to the responses topic.
  #
  # This is required in order to receive responses or commands
  # from the M2X API server. Note that #get_response already
  # subscribes the client.
  def subscribe
    mqtt_client.subscribe(response_topic)
    mqtt_client.subscribe(command_topic)
  end

  # Public: Send a payload to the M2X API server.
  #
  # payload - a Hash with the following keys:
  #           :id
  #           :method
  #           :resource
  #           :body
  # See https://m2x.att.com/developer/documentation/v2/mqtt
  def publish(payload)
    mqtt_client.publish(request_topic, payload.to_json)
  end

  # Public: Retrieve a response from the M2X Server.
  #
  # Returns a Hash with the response from the MQTT Server in M2X.
  # Optionally receives a block which will iterate through responses
  # and yield each one.
  def get_response
    mqtt_client.subscribe(response_topic)

    return packet_router.json_fetch(mqtt_client, response_topic) unless block_given?

    loop do
      yield packet_router.json_fetch(mqtt_client, response_topic)
    end
  end

  # Public: Retrieve a command from the M2X Server.
  #
  # Returns a Hash with the command from the MQTT Server in M2X.
  # Optionally receives a block which will iterate through commands
  # and yield each one.
  def get_command
    mqtt_client.subscribe(command_topic)

    return packet_router.json_fetch(mqtt_client, command_topic) unless block_given?

    loop do
      yield packet_router.json_fetch(mqtt_client, command_topic)
    end
  end

  # Public: Retrieve either a repsonse or a command from the M2X Server.
  #
  # Returns a Hash with the response or command from the MQTT Server in M2X.
  # Optionally receives a block which will iterate through commands
  # and yield each one.
  def get_response_or_command
    mqtt_client.subscribe(response_topic)
    mqtt_client.subscribe(command_topic)

    unless block_given?
      topic, payload = json_fetch_any(mqtt_client)
      payload = Command.new(self, payload)

      return payload
    end

    loop do
      topic, payload = json_fetch_any(mqtt_client)
      payload = Command.new(self, payload)

      yield payload
    end
  end

  [:get, :post, :put, :delete, :head, :options, :patch].each do |verb|
    define_method verb do |path, params=nil|
      request(verb, path, params)
    end
  end

  private

  attr_reader :packet_router

  def request(verb, path, params=nil)
    path  = versioned(path)
    body  = params || {}

    payload = {
      id:       SecureRandom.hex,
      agent:    USER_AGENT,
      method:   verb.upcase,
      resource: path,
      body:     body
    }

    publish(payload)

    { id: payload[:id] }
  end

  def request_topic
    @request_topic ||= "m2x/#{@api_key}/requests".freeze
  end

  def response_topic
    @response_topic ||= "m2x/#{@api_key}/responses".freeze
  end

  def command_topic
    @command_topic ||= "m2x/#{@api_key}/commands".freeze
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
