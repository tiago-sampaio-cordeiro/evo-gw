require 'logger'

module Devices
  # Método para lidar com o comando de registro
  def self.handle_reg(message, ws)
    puts "Registro recebido do dispositivo: #{message['sn']}"
    puts JSON.pretty_generate(message)

    case message["cmd"]
    when "reg"
      response = {
        ret: 'reg',
        result: true,
        cloudtime: Time.now.utc.iso8601,
        nosenduser: true
      }


      response_ws(ws, response)

    when "sendlog"
      puts "Logs recebidos do dispositivo: #{message['sn']}"
      puts "Total de logs: #{message['count']}"

      response = {
        ret: 'sendlog',
        result: true,
        count: message['count'],
        logindex: message['logindex'],
        cloudtime: Time.now.utc.iso8601,
        access: 1,
        message: 'Logs recebidos com sucesso'
      }

      response_ws(ws, response)
    end
  end
  private

  def self.response_ws(ws, response)
    ws.send(response.to_json)
    DeviceLogger.info "Resposta enviada ao dispositivo:"
    DeviceLogger.info JSON.pretty_generate(response)
  end
end
