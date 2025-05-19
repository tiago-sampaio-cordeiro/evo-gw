require 'rack'
require 'rack/app'
require 'faye/websocket'
require 'redis'
require 'logger'

require_relative 'app/services/websocket_handler'
require_relative 'app/services/redis_subscriber_service'
require_relative 'app/services/devices/sender'
require_relative 'app/helpers/handle_ws_command_helper.rb'

class Server < Rack::App
  include HandleWsCommandHelper

  LOGGER = Logger.new($stdout)
  REDIS = Redis.new(host: 'redis', port: 6379)
  CONNECTIONS = {}
  MUTEX = Mutex.new

  CONFIG = {
    redis: REDIS,
    connections: CONNECTIONS,
    mutex: MUTEX,
    logger: LOGGER
  }

  get '/pub/chat' do
    if Faye::WebSocket.websocket?(env)
      handler = WebSocketHandler.new(self, CONFIG)
      handler.call(env)
    else
      LOGGER.info "Requisição HTTP recebida: #{env['PATH_INFO']}"
      [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
    end
  end

  post 'pub/chat/:channel/:command' do
    channel = params['channel']
    command = params['command']
    args = []

    # Lista de comandos que NÃO precisam de body
    commands_without_body = ['user_list', 'clean_user', 'get_new_log', 'clean_log', 'initsys', 'reboot', 'clean_admin']

    if !commands_without_body.include?(command)
      begin
        body = request.body.read.strip

        if body.empty?
          LOGGER.error "❌ Corpo da requisição vazio para comando '#{command}'"
          return [400, { 'Content-Type' => 'application/json' }, [{ error: 'Missing JSON body' }.to_json]]
        end
        parsed = JSON.parse(body)

        if parsed.is_a?(Array)
          parsed.each do |item|
            args = item.is_a?(Hash) ? item.values : item
            handle_ws_command(channel, command, *args, config: CONFIG)
          end
        else
          args = parsed.is_a?(Hash) ? parsed.values : parsed
          handle_ws_command(channel, command, *args, config: CONFIG)
        end
      rescue JSON::ParserError => e
        LOGGER.error "❌ JSON inválido recebido: #{e.message}"
        return [400, { 'Content-Type' => 'application/json' }, [{ error: 'Invalid JSON' }.to_json]]
      end
    else
      handle_ws_command(channel, command, *args, config: CONFIG)
      [200, { 'Content-Type' => 'application/json' }, [{ status: 'Command dispatched' }.to_json]]
    end
  end
end
