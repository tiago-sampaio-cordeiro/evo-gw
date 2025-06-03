module HandleWsCommandHelper
  def handle_ws_command(channel, command, *args, config:)
    ws = config[:connections][channel]
    return { error: "Dispositivo não conectado" } unless ws

    Devices::Sender.send(ws, command, *args)

    redis = Redis.new(host: 'redis', port: 6379)
    key = "response:#{channel}"

    _, raw_response = redis.blpop(key)
    puts "resposta #{raw_response}"

    if raw_response
      JSON.parse(raw_response)
    else
      { error: 'Timeout esperando resposta do dispositivo' }
    end
  end

end
