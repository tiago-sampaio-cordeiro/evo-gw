require 'rack'
require 'rack/app'
require 'faye/websocket'
require 'redis'
require 'logger'

require_relative 'app/services/websocket_handler'
require_relative 'app/services/redis_subscriber_service'
require_relative 'app/services/devices/sender'
require_relative 'app/helpers/handle_ws_command_helper.rb'
require_relative 'app/ptrp_filter_info'

class Server < Rack::App
  include HandleWsCommandHelper

  LOGGER = Logger.new($stdout)
  REDIS = Redis.new(host: 'redis', port: 6379)
  CONNECTIONS = []
  MUTEX = Mutex.new

  CONFIG = {
    redis: REDIS,
    connections: CONNECTIONS,
    mutex: MUTEX,
    logger: LOGGER
  }

  # caminhos e variaveis para cada chamada função
  GET_COMMAND_ROUTES = {
    '/user_list' => 'user_list',
    '/user_info' => { command: 'user_info', params: %w[id]},
    '/username' => { command: 'username', params: %w[id]},
    '/new_log' => 'get_new_log',
    '/get_all_log' => { command: 'get_all_log', params: %w[init_date end_date]} #"2025-01-01", Time.now.strftime("%Y-%m-%d")
  }

  POST_COMMAND_ROUTES = {
    '/set_user_info' => { command: 'set_user_info', params: %w[id name] },
    '/delete_user' => { command: 'delete_user', params: %w[id] },
    '/set_username' => [command: 'set_username', params: %w[id name]],
    '/enable_user' => { command: 'enable_user', params: %w[id enable] }, # enable: 0 ou 1
    '/clean_user' => 'clean_user',
    '/clean_log' => 'clean_log',
    '/initsys' => 'initsys',
    '/reboot' => 'reboot',
    '/clean_admin' => 'clean_admin',
    '/set_time' => { command: 'set_time', params: %w[time]} # time: Time.now
  }

  # Laço de repetição para criar rotas GET
  GET_COMMAND_ROUTES.each do |path, config|
    get path do
      if config.is_a?(Hash)
        req = Rack::Request.new(env)

        args = config[:params].map do |param|
          valor = req.POST[param]
          valor
        end
        handle_ws_command(current_ws, *args)
      else
        handle_ws_command(current_ws, *Array(config))
      end
    end
  end

  # Laço de repetição para criar rotas POST
  POST_COMMAND_ROUTES.each do |path, config|
    post path do
      if config.is_a?(Hash)
        req = Rack::Request.new(env)

        args = config[:params].map do |param|
          valor = req.POST[param]
          valor
        end
        handle_ws_command(current_ws, config[:command], *args)
      else
        handle_ws_command(current_ws, *Array(config))
      end
    end
  end

  get '/pub/chat' do
    if Faye::WebSocket.websocket?(env)
      handler = WebSocketHandler.new(self, CONFIG)
      handler.call(env)
    else
      LOGGER.info "Requisição HTTP recebida: #{env['PATH_INFO']}"
      [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
    end
  end

  get '/' do
    equipment = PtrpFilterInfo.new
    list = equipment.present_on_the_list(REDIS)
  end

  private

  def current_ws
    CONNECTIONS.first
  end
end

# TODO
# Esta sendo recuperado a primeira conexão de forma estatica para desenvolvimento
# Os valores como id do usuario e datas estão sendo passados fixo para teste dos metodos
# Será feita uma nova branch para criação do mocks para sumulação de requisição vinda do PTRP
