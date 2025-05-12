require 'logger'

class RedisSubscriberService
  Logger = Logger.new($stdout)

  @subscribed_channels = {}
  @mutex = Mutex.new

  def self.subscribed?(channel)
    @mutex.synchronize { @subscribed_channels.key?(channel) }
  end

  def self.start(channel:, connections:, mutex:)
    return if subscribed?(channel)

    @mutex.synchronize { @subscribed_channels[channel] = true }

    Thread.new do
      subscriber = Redis.new(host: 'redis', port: 6379)
      loop do
        begin
          Logger.info "🔄 Subscrição ao canal Redis '#{channel}' iniciada..."
          subscriber.subscribe(channel) do |on|
            on.message do |_chan, message|
              mutex.synchronize do
                connections.each { |ws| ws.send(message) }
              end
            end
          end
        rescue => e
          Logger.info "⚠️ Erro no Redis (canal: #{channel}): #{e.message}. Tentando reconectar..."
          sleep 2
          retry
        end
      end
    end
  end
end
