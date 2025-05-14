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
    '/user_list'     => 'user_list',
    '/user_info'     => ['user_info', 1],
    '/username'      => ['username', 1],
    '/new_log'       => 'get_new_log',
    '/get_all_log'   => ['get_all_log', "2025-01-01", Time.now.strftime("%Y-%m-%d")]
  }

  POST_COMMAND_ROUTES = {
    '/set_user_info' => ['set_user_info', 1, "Pablo Pereira"],
    '/delete_user'   => ['delete_user', 1],
    '/set_username'  => ['set_username', 1, "pablito"],
    '/enable_user'   => ['enable_user', 1, 1],
    '/clean_user'    => 'clean_user',
    '/clean_log'     => 'clean_log',
    '/initsys'       => 'initsys',
    '/reboot'        => 'reboot',
    '/clean_admin' => 'clean_admin',
    '/set_time' => ['set_time', Time.now]
  }

  # Laço de repetição para criar rotas GET
  GET_COMMAND_ROUTES.each do |path, command|
    get path do
      if command.is_a?(Array)
        handle_ws_command(current_ws, *command)
      else
        handle_ws_command(current_ws, command)
      end
    end
  end

  # Laço de repetição para criar rotas POST
  POST_COMMAND_ROUTES.each do |path, command|
    post path do
      if command.is_a?(Array)
        handle_ws_command(current_ws, *command)
      else
        handle_ws_command(current_ws, command)
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
