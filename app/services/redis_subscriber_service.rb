require 'logger'
require 'redis'
require 'json'

class RedisSubscriberService

  def initialize(channel:, ws:, mutex_subscribed_channels:, logger:, subscribed_channels:)
    @channel = channel
    @ws = ws
    @mutex_subscribed_channels = mutex_subscribed_channels
    @logger = logger
    @subscribed_channels = subscribed_channels
    @thread = nil
    @stop_requested = false
  end

  def start
    return if @mutex_subscribed_channels.synchronize { @subscribed_channels.key?(@channel) }
    return if @thread&.alive?

    @mutex_subscribed_channels.synchronize { @subscribed_channels[@channel] = true }

    @thread = Thread.new do
      begin
        subscriber = Redis.new(host: 'redis', port: 6379)

        @logger.info "Subscrição ao canal Redis '#{@channel}' iniciada..."

        subscriber.subscribe(@channel) do |on|
          on.message do |_chan, message|

            next if @stop_requested

            begin
              @logger.debug "Mensagem recebida no canal '#{@channel}': #{message}"

              payload = JSON.parse(message)
              command = payload['cmd']
              args = payload['args'] || []

              if command
                @mutex_subscribed_channels.synchronize do
                  Devices::Sender.send(@ws, command, *args)
                end
              else
                @logger.warn "Payload recebido sem comando no canal '#{@channel}': #{payload}"
              end
            rescue JSON::ParserError => e
              @logger.error "Erro ao fazer parse do JSON no canal '#{@channel}': #{e.message}"
            rescue => e
              @logger.error "Erro ao processar comando no canal '#{@channel}': #{e.message}"
            end
          end
        end

      rescue Redis::CannotConnectError => e
        @logger.error "Falha ao conectar ao Redis (canal: #{@channel}): #{e.message}"

      rescue => e
        @logger.error "Erro no Redis (canal: #{@channel}): #{e.message}. Tentando reconectar..."
        sleep 2
        retry

      ensure
        # Remove só se existir para evitar remover indevidamente
        @mutex_subscribed_channels.synchronize do
          if @subscribed_channels.key?(@channel)
            @subscribed_channels.delete(@channel)
            @logger.info "❌ Subscrição ao canal '#{@channel}' foi encerrada."
          end
        end
      end
    end
  end

  def stop
    @stop_requested = true
    if @thread&.alive?
      @thread.kill
      @logger.info "Thread da subscrição do canal '#{@channel}' terminada via kill."
    end

    @mutex_subscribed_channels.synchronize do
      @subscribed_channels.delete(@channel)
    end
    @logger.info "Subscrição ao canal '#{@channel}' parada manualmente."
  end
end


