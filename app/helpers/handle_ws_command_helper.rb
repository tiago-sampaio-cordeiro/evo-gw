module HandleWsCommandHelper
  def handle_ws_command(ws, command, *args)
    if ws
      Devices::Sender.send(ws, command, *args)
      { status: "Comando enviado #{command}" }
    else
      { error: "Nenhuma conexão WebSocket ativa" }
    end
  end
end