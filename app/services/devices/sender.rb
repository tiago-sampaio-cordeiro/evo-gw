module Devices
  module Sender
    def self.send_get_user_list(ws)
      command = {
        cmd: 'getuserlist',
        stn: true
      }

      ws.send(command.to_json)
      puts "Comando 'getuserlist' enviado para o aparelho"
    end

    def self.userinfo(ws, user)
      command = {
        cmd: 'getuserinfo',
        user: user,
        backupnum: 10
      }

      ws.send(command.to_json)
      puts "commando 'getuserinfo' enviado para o aparelho"
    end
  end
end
