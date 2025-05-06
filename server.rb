require 'rack'
require 'rack/app'
require 'faye/websocket'
require 'redis'
require 'logger'

require_relative 'app/services/websocket_handler'
require_relative 'app/services/redis_subscriber_service'

class Server < Rack::App
  @logger = Logger.new($stdout)
  @redis = Redis.new(host: 'redis', port: 6379)
  @connections = []
  @mutex = Mutex.new

  @config = {
    redis: @redis,
    connections: @connections,
    mutex: @mutex,
    logger: @logger
  }

  get '/pub/chat' do
    if Faye::WebSocket.websocket?(env)
      handler = WebSocketHandler.new(self, self.class.instance_variable_get(:@config))
      handler.call(env)
    else
      self.class.instance_variable_get(:@logger).info "Requisição HTTP recebida: #{env['PATH_INFO']}"
      [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
    end
  end
end
