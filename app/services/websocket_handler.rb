require 'json'
require 'faye/websocket'
require 'eventmachine'
require_relative 'devices/evo'

class WebSocketHandler

  GLOBAL_SENDLOG_CHANNEL = 'sendlog_channel'.freeze

  def initialize(app, config = {})
    @app = app
    @redis = config[:redis]
    @connections = config[:connections]
    @mutex = config[:mutex]
    @logger = config[:logger]
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env)

      # Evento de abertura
      ws.on :open do |event|
        @logger.info 'WebSocket aberto'

        @mutex.synchronize do
          @connections[ws.object_id] = ws
        end
      end

      # Evento de mensagem
      ws.on :message do |event|
        message = JSON.parse(event.data)
        sn = message['sn']
        command = message['cmd']
        next unless sn

        Devices.handle_reg(message, ws)

        if command == 'sendlog'
          @logger.info "Recebido sendlog de #{sn}"
          @redis.publish(GLOBAL_SENDLOG_CHANNEL, event.data)
          next
        end

        # Inicia subscrição dinâmica se ainda não existe
        unless RedisSubscriberService.subscribed?(sn)
          RedisSubscriberService.start(
            channel: sn,
            ws: ws,
            mutex: @mutex,
            logger: @logger
          )
        end
      end

      # Evento de erro
      ws.on :error do |event|
        @logger.error "Erro no WebSocket: #{event.message}"
      end

      # Evento de fechamento
      ws.on :close do |event|
        @logger.info "Conexão encerrada. Código: #{event.code}, Razão: #{event.reason}"
        @mutex.synchronize do
          @connections.delete(ws.object_id)
        end
        ws = nil
      end

      # Retorna a resposta assincrona do WebSocket
      ws.rack_response
    else
      @app.call(env)
    end
  end
end
