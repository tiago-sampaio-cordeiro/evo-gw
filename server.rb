require 'rack'
require 'rack/app'
require 'faye/websocket'
require 'redis'

require_relative 'app/services/websocket_handler'
require_relative 'app/services/redis_subscriber_service'
require_relative 'app/services/devices/sender'
require_relative 'app/helpers/handle_ws_command_helper.rb'

class Server < Rack::App
  include HandleWsCommandHelper

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

  get '/user_list' do
    handle_ws_command(current_ws, 'user_list')
  end

  get '/user_info' do
    handle_ws_command(current_ws, 'user_info', 1)
  end

  post '/set_user_info' do
    handle_ws_command(current_ws, 'set_user_info', 1, "Pablo Pereira")
  end

  post '/delete_user' do
    handle_ws_command(current_ws, 'delete_user', 1)
  end

  get '/username' do
    handle_ws_command(current_ws, 'username', 1)
  end

  post '/set_username' do
    handle_ws_command(current_ws, 'set_username', 1, "pablito")
  end

  post '/enable_user' do
    handle_ws_command(current_ws, 'enable_user', 1, 1)
  end

  post '/clean_user' do
    handle_ws_command(current_ws, 'clean_user')
  end

  get '/new_log' do
    handle_ws_command(current_ws, 'get_new_log')
  end

  get '/get_all_log' do
    handle_ws_command(current_ws, 'get_all_log', "2025-01-01", Time.now.strftime("%Y-%m-%d"))
  end

  post '/clean_log' do
    handle_ws_command(current_ws, 'clean_log')
  end

  post '/initsys' do
    handle_ws_command(current_ws, 'initsys')
  end

  post '/reboot' do
    handle_ws_command(current_ws, 'reboot')
  end

  post '/clean_admin' do
    handle_ws_command(current_ws, 'clean_admin')
  end

  post '/set_time' do
    handle_ws_command(current_ws, 'set_time', Time.now)
  end

  private
  def current_ws
    self.class.instance_variable_get(:@connections).first
  end
end

# TODO
# Esta sendo recuperado a primeira conexão de forma estatica para desenvolvimento
# Os valores como id do usuario e datas estão sendo passados fixo para teste dos metodos
# Será feita uma nova branch para criação do mocks para sumulação de requisição vinda do PTRP
