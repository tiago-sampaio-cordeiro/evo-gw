module HandleWsCommandHelper
  def handle_ws_command(channel, command, *args, config:)
    ws = config[:connections][channel]

    unless ws
      config[:logger].error "❌ Nenhuma conexão WebSocket ativa para o canal '#{channel}'"
      return
    end

    config[:logger].info "➡️  Enviando comando '#{command}' para canal '#{channel}' com args: #{args.inspect}"

    Devices::Sender.send(ws, command, *args)
  rescue => e
    config[:logger].error "🔥 Erro ao processar comando '#{command}' no canal '#{channel}': #{e.message}"
    config[:logger].error e.backtrace.join("\n")
  end
end
