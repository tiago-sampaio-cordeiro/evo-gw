require 'rack'
require 'rack/app'
require 'faye/websocket'
require 'redis'
require 'logger'

require_relative 'app/services/websocket_handler'
require_relative 'app/services/redis_subscriber_service'
require_relative 'app/services/devices/sender'

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

  get '/send_getuserlist' do
    # Pegando a primeira conexão ativa (simples para exemplo)
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.send_get_user_list(ws)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  get '/userinfo' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.userinfo(ws, 1)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado userInfo' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post '/set_user_info' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.set_user_info(ws, 1)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado userInfo' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end
end
