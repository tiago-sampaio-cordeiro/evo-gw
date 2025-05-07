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
      Devices::Sender.set_user_info(ws, 2)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado SetuserInfo' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post '/delete_user' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.delete_user(ws, 1)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado DeleteUser' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  get '/username' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.get_username(ws, 1)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado getUsername' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post '/enable_user' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.enable_user(ws, 1)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado enableUser' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post 'clean_user' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.clean_user(ws, 1)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado cleanUser' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  get 'get_all_log' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.get_all_log(ws, "2025-01-01", Time.now.strftime("%Y-%m-%d"))
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado getAllLog' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post 'clean_log' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.clean_log(ws)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado cleanLog' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post 'initsys' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.initsys(ws)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado initsys' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post 'reboot' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.reboot(ws)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado reboot' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end

  post 'cleanadmin' do
    ws = self.class.instance_variable_get(:@connections).first

    if ws
      Devices::Sender.cleanadmin(ws)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'comando enviado clearadmin' }.to_json]]
    else
      [500, { 'Content-Type' => 'application/json' }, [{ error: 'Nenhuma conexão WebSocket ativa' }.to_json]]
    end
  end
end

# TODO
# Esta sendo recuperado a primeira conexão de forma estatica para desenvolvimento
# Os valores como id do usuario e datas estão sendo passados fixo para teste dos metodos
# Será feita uma nova branch para criação do mocks para sumulação de requisição vinda do PTRP
