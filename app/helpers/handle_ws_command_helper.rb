module HandleWsCommandHelper
  def handle_ws_command(channel, command, *args, config:)
    ws = config[:connections][channel]
    return { error: "Dispositivo não conectado" } unless ws

    command_data = Devices::Sender.send(ws, command, *args)
    ws.send(command_data.to_json)

    redis = Redis.new(host: 'redis', port: 6379)
    key = "response:#{channel}"

    # Espera até 1 segundo (1s = 1 segundo no BLPOP)
    _, raw_response = redis.blpop(key, timeout: 5)

    if raw_response
      JSON.parse(raw_response)
    else
      { error: 'Timeout esperando resposta do dispositivo' }
    end
  end

end
