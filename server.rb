require 'sinatra'
require 'faye/websocket'
require 'puma'
require 'redis'
require 'json'
require 'logger'

set :server, 'puma'
set :views, File.join(settings.root, 'app', 'views')

redis = Redis.new(host: 'redis', port: 6379)
channel = 'canal_teste'

connections = []
connections_mutex = Mutex.new

Thread.new do
  subscriber = Redis.new(host: 'redis', port: 6379) # Conexão separada para subscrição
  loop do
    begin
      puts "🔄 Subscrição ao canal Redis iniciada..."
      subscriber.subscribe(channel) do |on|
        on.message do |_channel, message|
          connections_mutex.synchronize do
            connections.each { |ws| ws.send(message) if ws.ready_state == Faye::WebSocket::OPEN }
          end
        end
      end
    rescue => e
      puts "⚠️ Erro no Redis: #{e.message}. Tentando reconectar..."
      sleep 2
      retry
    end
  end
end

# endpoint para testes entre dispositivos
get '/welcome' do
  send_file File.join(settings.public_folder, 'index.html')  # Serve o arquivo HTML estático
end

# endpoint do servidor
get '/' do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env)

    client_ip = env['REMOTE_ADDR'] || 'Desconhecido'

    ws.on :open do |_event|
      connections_mutex.synchronize { connections << ws }
      logger.info "Conexão estabelecida com o cliente #{client_ip}"
    end

    ws.on :message do |event|
      begin

        redis.publish(channel, event.data)


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

      rescue JSON::ParserError => e
        logger.error "Erro ao processar JSON: #{e.message}"
        # Resposta de erro para JSON inválido
        error_response = {
          ret: 'error',
          reason: 'Invalid JSON format'
        }
        ws.send(error_response.to_json)

      rescue => e
        logger.error "Erro inesperado: #{e.message}"
        ws.send({ ret: 'error', reason: 'Internal server error' }.to_json)
      end
    end
    # Log para desconexão
    ws.on :close do |event|
      connections_mutex.synchronize { connections.delete(ws) }
      logger.info "Cliente #{client_ip} desconectado: Codigo=#{event.code}, Razão=#{event.reason}"
    end

    # Log para erros
    ws.on :error do |event|
      logger.error "Erro de conexão: #{event.message}"
    end

    # Retorna a resposta WebSocket
    ws.rack_response
    else
      # Log para requisições HTTP normais
      puts "Requisição HTTP recebida: #{env['PATH_INFO']}"
      [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
  end
end







