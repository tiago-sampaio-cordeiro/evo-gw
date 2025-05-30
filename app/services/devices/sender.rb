require 'logger'

module Devices
  module Sender
    LOGGER = Logger.new($stdout)

    COMMANDS = {
      'user_list' => ->(ws) { user_list(ws) },
      'user_info' => ->(ws, *args) { user_info(ws, *args) },
      'set_user_info' => ->(ws, *args) { set_user_info(ws, *args) },
      'delete_user' => ->(ws, *args) { delete_user(ws, *args) },
      'username' => ->(ws, *args) { get_username(ws, *args) },
      'set_username' => ->(ws, *args) { set_username(ws, *args) },
      'enable_user' => ->(ws, *args) { enable_user(ws, *args) },
      'clean_user' => ->(ws) { clean_user(ws) },
      'get_new_log' => ->(ws) { get_new_log(ws) },
      'get_all_log' => ->(ws, *args) { get_all_log(ws, *args) },
      'clean_log' => ->(ws) { clean_log(ws) },
      'initsys' => ->(ws) { initsys(ws) },
      'reboot' => ->(ws) { reboot(ws) },
      'clean_admin' => ->(ws) { clean_admin(ws) },
      'set_time' => ->(ws, *args) { set_time(ws, *args) }
    }.freeze

    def self.send(ws, command, *args)
      action = COMMANDS[command]

      if action
        action.call(ws, *args)
      else
        LOGGER.error "Comando desconhecido: #{command}"
      end
    end

    private

    def self.user_list(ws)
      command = {
        cmd: 'getuserlist',
        stn: true
      }

      send_ws_command(ws, command)
    end

    def self.user_info(ws, user)
      command = {
        cmd: 'getuserinfo',
        enrollid: user,
        backupnum: 10
      }

      send_ws_command(ws, command)
    end

    def self.set_user_info(ws, user, name, record)
      command = {
        cmd: 'setuserinfo',
        enrollid: user.to_i,
        name: name,
        backupnum: 10,
        record: record
      }

      send_ws_command(ws, command)
    end

    # servidor retorna true para a operação, mas o user não é deletado do aparelho
    def self.delete_user(ws, user)
      command = {
        cmd: 'deleteuser',
        enrollid: user,
        backupnum: 10 # Apaga todos os dados do usuário
      }

      send_ws_command(ws, command)
    end

    def self.get_username(ws, user)
      command = {
        cmd: 'getusername',
        enrollid: user
      }

      send_ws_command(ws, command)
    end

    def self.set_username(ws, user, name)
      command = {
        cmd: 'setusername',
        count: 1, # numero de usuarios que sera setado o nome
        record: [
          {
            enrollid: user,
            name: name
          }
        ]
      }

      send_ws_command(ws, command)
    end

    def self.enable_user(ws, user, value)
      command = {
        cmd: 'enableuser',
        enrollid: user,
        enflag: value # valor pode ser 0 ou 1, 0 para desabilitar e 1 para habilitar
      }

      send_ws_command(ws, command)
    end

    # Remove todos os usuarios do equipamento
    def self.clean_user(ws)
      command = {
        cmd: 'cleanuser'
      }

      send_ws_command(ws, command)
    end

    def self.get_new_log(ws)
      command = {
        cmd: 'getnewlog',
        stn: true
      }

      send_ws_command(ws, command)
    end

    def self.get_all_log(ws, init_data, end_data)
      command = {
        cmd: 'getalllog',
        stn: true,
        from: init_data, # Data inicial
        to: end_data # Data final
      }

      send_ws_command(ws, command)
    end

    def self.clean_log(ws)
      command = {
        cmd: 'cleanlog'
      }

      send_ws_command(ws, command)
    end

    # Apaga todos os logs e todos os usuario, mas mantem as config
    def self.initsys(ws)
      command = {
        cmd: 'initsys'
      }

      send_ws_command(ws, command)
    end

    def self.reboot(ws)
      command = {
        cmd: 'reboot'
      }

      send_ws_command(ws, command)
    end

    def self.clean_admin(ws)
      command = {
        cmd: 'cleanadmin'
      }

      send_ws_command(ws, command)
    end

    def self.set_time(ws, time)
      command = {
        cmd: 'settime',
        cloudtime: time
      }

      send_ws_command(ws, command)
    end

    def self.send_ws_command(ws, command)
      ws.send(command.to_json)
      LOGGER.info "[Devices::Sender] Comando '#{command[:cmd]}' enviado para o aparelho"
      command
    end
  end
end
