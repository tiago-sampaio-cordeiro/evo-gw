require 'json'
require 'faye/websocket'
require 'eventmachine'
require_relative 'devices/evo'

class WebSocketHandler
  def initialize(app, config = {})
    @app = app
    @redis = config[:redis]
    @connections = config[:connections]
    @mutex = config[:mutex]
    @logger = config[:logger]
    @channel = config[:channel]
  end

  def call(env)
    if Faye::WebSocket.websocket?(env)
      ws = Faye::WebSocket.new(env)

      # Evento de abertura
      ws.on :open do |event|
        puts 'WebSocket aberto'

        @mutex.synchronize do
          @connections << ws
        end
      end

      # Evento de mensagem
      ws.on :message do |event|
        message = JSON.parse(event.data)
        puts "Mensagem recebida: #{message}"
        puts "COMANDO: #{message["cmd"]}"

        Devices.handle_reg(message, ws)
      end

      # Evento de erro
      ws.on :error do |event|
        puts "Erro no WebSocket: #{event.message}"
      end

      # Evento de fechamento
      ws.on :close do |event|
        puts "Conexão encerrada. Código: #{event.code}, Razão: #{event.reason}"
        @mutex.synchronize do
          @connections.delete(ws)
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
