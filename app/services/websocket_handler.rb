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
    @mutex_connections = config[:mutex_connections]
    @mutex_subscribed_channels = config[:mutex_subscribed_channels]
    @logger = config[:logger]
    @pending_response = config[:pending_response]
    @subscribed_channels = {}
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env)

      # Evento de abertura
      ws.on :open do |event|
        @mutex_connections.synchronize do
          @connections[ws] = nil
          client_ip = env['REMOTE_ADDR'] || 'Desconhecido'
          @logger.info "Cliente conectado: #{client_ip}"
        end
      end

      # Evento de mensagem
      ws.on :message do |event|
        message = JSON.parse(event.data)
        sn = message['sn']

        @mutex_connections.synchronize do
          if sn
            @redis.lpush("response:#{sn}", event.data)
            @redis.del("response:#{sn}")
          end
        end

        command = message['cmd']

        if sn
          @mutex_connections.synchronize do
            @connections[sn] = ws
          end
        end

        Devices.handle_reg(message, ws)

        if command == 'sendlog'
          @logger.info "Recebido sendlog de #{sn}"
          @redis.publish(GLOBAL_SENDLOG_CHANNEL, event.data)
          next
        end

        redis_service = RedisSubscriberService.new(
          channel: sn,
          ws: ws,
          mutex_subscribed_channels: @mutex_subscribed_channels,
          logger: @logger,
          subscribed_channels: @subscribed_channels
        )
        redis_service.start
      end

      # Evento de erro
      ws.on :error do |event|
        @logger.error "Erro no WebSocket: #{event.message}"
      end

      # Evento de fechamento
      ws.on :close do |event|
        @logger.info "Conexão encerrada. Código: #{event.code}, Razão: #{event.reason}"
        @mutex_connections.synchronize do
          sn = @connections.key(ws)
          @connections.delete(sn)
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
