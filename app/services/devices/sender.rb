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
        enrollid: user,
        backupnum: 10
      }

      ws.send(command.to_json)
      puts "commando 'getuserinfo' enviado para o aparelho"
    end

    def self.set_user_info(ws, user)
      command = {
        cmd: 'setuserinfo',
        enrollid: user,
        name: "Pablo",
        backupnum: 0
      }

      ws.send(command.to_json)
      puts "commando 'setuserinfo' enviado para o aparelho"
    end

    # servidor retorna true para a operação, mas o user não é deletado do aparelho
    def self.delete_user(ws, user)
      command = {
        cmd: 'deleteuser',
        enrollid: user,
        backupnum: 0
      }

      ws.send(command.to_json)
      puts "comando 'deleteuser' enviado para o aparelho"
    end

    def self.get_username(ws, user)
      command = {
        cmd: 'getusername',
        enrollid: user
      }

      ws.send(command.to_json)
      puts "Comando 'getusername' enviado para o aparelho"
    end

    # def self.setUsername(ws, user)
    #   command = {
    #     cmd: 'setusername',
    #     count: , # numero de usuarios que sera setado o nome
    #     record: [
    #       {
    #         enrollid: user,
    #         name: "Teste"
    #       }
    #     ]
    #   }
    # end

    def self.enable_user(ws, user)
      command = {
        cmd: 'enableuser',
        enrollid: user,
        enflag: 1 # valor pode ser 0 ou 1, 0 para desabilitar e 1 para habilitar
      }

      ws.send(command.to_json)
      puts "Comando 'enableuser' enviado para o aparelho"
    end

    # Remove todos os usuarios do equipamento
    def self.clean_user(ws)
      command = {
        cmd: 'cleanuser'
      }

      ws.send(command.to_json)
      puts "Comando 'enableuser' enviado para o aparelho"
    end

    def self.get_all_log(ws, initi_data, end_data)
      command = {
        cmd: 'getalllog',
        stn: true,
        from: initi_data, # Data inicial
        to: end_data # Data final
      }

      ws.send(command.to_json)
      puts "Comando 'getalllog' enviado para o aparelho"
    end

    def self.clean_log(ws)
      command = {
        cmd: 'cleanlog'
      }

      ws.send(command.to_json)
      puts "Commando 'cleanlog' enviado para o aparelho"
    end


  end
end
