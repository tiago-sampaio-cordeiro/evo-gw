require 'logger'

class RedisSubscriberService

  @subscribed_channels = {}
  @mutex = Mutex.new

  def self.subscribed?(channel)
    @mutex.synchronize { @subscribed_channels.key?(channel) }
  end

  def self.start(channel:, ws:, mutex:, logger:)
    return if subscribed?(channel)

    @mutex.synchronize { @subscribed_channels[channel] = true }

    Thread.new do
      begin
        subscriber = Redis.new(host: 'redis', port: 6379)

        logger.info "🔄 Subscrição ao canal Redis '#{channel}' iniciada..."

        subscriber.subscribe(channel) do |on|
          on.message do |_chan, message|
            begin
              payload = JSON.parse(message)

              command = payload['cmd']
              args = payload['args'] || []

              if command
                mutex.synchronize do
                  Devices::Sender.send(ws, command, *args)
                end
              else
                logger.warn "⚠️ Payload recebido sem comando no canal '#{channel}': #{payload}"
              end
            rescue JSON::ParserError => e
              logger.error "❌ Erro ao fazer parse do JSON no canal '#{channel}': #{e.message}"
            rescue => e
              logger.error "❌ Erro ao processar comando no canal '#{channel}': #{e.message}"
            end
          end
        end

      rescue Redis::CannotConnectError => e
        logger.error "⚠️ Falha ao conectar no Redis (canal: #{channel}): #{e.message}. Tentando reconectar..."
        sleep 2
        retry

      rescue => e
        logger.error "⚠️ Erro no Redis (canal: #{channel}): #{e.message}. Tentando reconectar..."
        sleep 2
        retry

      ensure
        @mutex.synchronize { @subscribed_channels.delete(channel) }
        logger.info "❌ Subscrição ao canal '#{channel}' foi encerrada."
      end
    end
  end
end
