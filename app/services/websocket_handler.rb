class WebSocketHandler
  def initialize(env, redis, connections, connections_mutex, logger, channel)
    @env = env
    @redis = redis
    @connections = connections
    @connections_mutex = connections_mutex
    @logger = logger
    @channel = channel
  end

  def call
    ws = Faye::WebSocket.new(@env)

    client_ip = @env['REMOTE_ADDR'] || 'Desconhecido'

    ws.on :open do |_event|
      @connections_mutex.synchronize { @connections << ws }
      @logger.info "Conexão estabelecida com o cliente #{client_ip}"
    end

    ws.on :message do |event|
      begin
        @redis.publish(@channel, event.data)
      rescue JSON::ParserError => e
        error_response = { ret: 'error', reason: 'Invalid JSON format' }
        ws.send(error_response.to_json)
        @logger.error "Erro ao processar JSON: #{e.message}"
      rescue => e
        @logger.error "Erro inesperado: #{e.message}"
        ws.send({ ret: 'error', reason: 'Internal server error' }.to_json)
      end
    end

    ws.on :close do |event|
      @connections_mutex.synchronize { @connections.delete(ws) }
      @logger.info "Cliente #{client_ip} desconectado: Codigo=#{event.code}, Razão=#{event.reason}"
    end

    ws.on :error do |event|
      @logger.error "Erro de conexão: #{event.message}"
    end

    # Garantir que a resposta seja compatível com o Rack
    # Retornando um status 101 para a conexão WebSocket
    [101, { 'upgrade' => 'websocket', 'connection' => 'upgrade' }, ws.rack_response]
  end
end
