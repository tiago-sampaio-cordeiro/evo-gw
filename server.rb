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
  @channel = 'canal_teste'
  @connections = []
  @mutex = Mutex.new

  @config = {
    redis: @redis,
    connections: @connections,
    mutex: @mutex,
    logger: @logger,
    channel: @channel
  }

  # Evita múltiplas inicializações da subscrição Redis
  @subscriber_started ||=
    begin
      RedisSubscriberService.start(
        channel: @channel,
        connections: @connections,
        mutex: @mutex
      )
      true
    end

  def self.get_user_list
    command = {
      cmd: 'getuserlist',
      stn: true
    }

    message = command.to_json

    @mutex.synchronize do
      @connections.each do |ws|
        ws.send(message)
      end
    end

    @logger.info "Comando 'getuserlist' enviado para todos aparelhos conectados"
  end

  get '/send_getuserlist' do
    Server.get_user_list
    [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado' }.to_json]]
  end

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
