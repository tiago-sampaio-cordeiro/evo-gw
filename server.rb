require 'rack'
require 'faye/websocket'
require 'redis'
require 'logger'

require_relative 'app/services/websocket_handler'
require_relative 'app/services/redis_subscriber_service'

class Server
  def initialize
    @logger = Logger.new($stdout)
    @redis = Redis.new(host: 'redis', port: 6379)
    @channel = 'canal_teste'
    @connections = []
    @mutex = Mutex.new

    RedisSubscriberService.start(
      channel: @channel,
      connections: @connections,
      mutex: @mutex
    )
  end

  def call(env)
    request = Rack::Request.new(env)
    case request.path_info
    when "/"
      if Faye::WebSocket.websocket?(env)
        handler = WebSocketHandler.new(env, @redis, @connections, @mutex, @logger, @channel)
        return handler.call
      else
        puts "Requisição HTTP recebida: #{env['PATH_INFO']}"
        [200, { 'content-type' => 'text/plain' }, ['Hello']]
      end
    else
      [404, { 'content-type' => 'text/plain' }, ['Página não encontrada']]
    end
  end
end


# # endpoint para testes entre dispositivos
# get '/welcome' do
#   send_file File.join(settings.public_folder, 'index.html') # Serve o arquivo HTML estático
# end
#
# # endpoint do servidor
# get '/' do
#   if Faye::WebSocket.websocket?(request.env)
#     handler = WebSocketHandler.new(request.env, redis, connections, connections_mutex, logger, channel)
#     handler.call
#   else
#     puts "Requisição HTTP recebida: #{env['PATH_INFO']}"
#     [200, { 'content-type' => 'text/plain' }, ['Hello']]
#   end
# end

# logica relacionada ao EVO

# Converte a mensagem recebida de JSON para um hash
# message = JSON.parse(event.data)
# if message['cmd'] == 'reg'
#   logger.error "Registro recebido do dispositivo: #{message['sn']}"
#   puts JSON.pretty_generate(message)
#
#   response = {
#     ret: 'reg',
#     result: true,
#     cloudtime: Time.now.utc.iso8601,
#     nosenduser: true
#   }
#
#   ws.send(response.to_json)
#   logger.info "Resposta enviada ao dispositivo:"
#   puts JSON.pretty_generate(response)
# elsif message['cmd'] == 'sendlog'
#   logger.info "Logs recebidos do dispositivo: #{message['sn']}"
#   logger.info "Total de logs: #{message['count']}"
#
#   # Iterar pelos registros de log recebidos
#   if message['record']
#     message['record'].each_with_index do |log, index|
#       puts "Log #{index + 1}:"
#       puts JSON.pretty_generate(log)
#     end
#   else
#     logger.info "Nenhum registro de log encontrado"
#   end
#
#   response = {
#     ret: 'sendlog',
#     result: true,
#     count: message['count'],
#     logindex: message['logindex'],
#     cloudtime: Time.now.utc.iso8601,
#     access: 1,
#     message: 'Logs recebidos com sucesso'
#   }
#
#   ws.send(response.to_json)
#   logger.info "Resposta enviada ao dispositivo:"
#   puts JSON.pretty_generate(response)
#
# else
#   logger.info "Comando não reconhecido: #{message['cmd']}"
#   ws.send({ ret: 'error', reason: 'Unknown command' }.to_json)
# end