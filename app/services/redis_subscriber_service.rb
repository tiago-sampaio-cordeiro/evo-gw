require 'logger'

class RedisSubscriberService
  LOGGER = Logger.new($stdout)

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

        LOGGER.info "🔄 Subscrição ao canal Redis '#{channel}' iniciada..."

        subscriber.subscribe(channel) do |on|
          on.message do |_chan, message|
            mutex.synchronize do
              ws.send(message)
            end
          end
        end


      rescue Redis::CannotConnectError => e
        LOGGER.error "⚠️ Falha ao conectar no Redis (canal: #{channel}): #{e.message}. Tentando reconectar..."
        sleep 2
        retry

      rescue => e
        LOGGER.error "⚠️ Erro no Redis (canal: #{channel}): #{e.message}. Tentando reconectar..."
        sleep 2
        retry

      ensure
        @mutex.synchronize { @subscribed_channels.delete(channel) }
        LOGGER.info "❌ Subscrição ao canal '#{channel}' foi encerrada."
      end
    end
  end
end
