require 'redis'
class RedisSubscriberService
  def self.start(channel:, connections:, mutex:)
    Thread.new do
      subscriber = Redis.new(host: 'redis', port: 6379) # Conexão separada para subscrição
      loop do
        begin
          puts "🔄 Subscrição ao canal Redis iniciada..."
          subscriber.subscribe(channel) do |on|
            on.message do |_channel, message|
              mutex.synchronize do
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
  end
end