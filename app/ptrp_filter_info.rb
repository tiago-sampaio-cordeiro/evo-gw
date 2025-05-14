require_relative 'mocks/equipment_mock'
require 'redis'
require 'net/http'
require 'uri'

class PtrpFilterInfo
  def equipment_filter
    EquipmentMock.equipaments.map do |equipament|
      {
        name: equipament[:name],
        fabricante: equipament[:fabricante],
        nserie_rep: equipament[:nserie_rep]
      }
    end
  end

  def present_on_the_list(redis)
    list_equipaments = equipment_filter
    sn = redis.get("sn")

    if list_equipaments.none? { |equipment| equipment[:nserie_rep] == sn }
      puts "não presente"
      add_equipment(redis)Cre
    end
  end

  def add_equipment(redis)
    equip = JSON.parse(redis.get("equipamento"))
    new_equip = {
      "name": equip['sn'],
      "fabricante": 'evo',
      "modelo_equipamento": equip['devinfo']['modelname'],
      "ip": equip['devinfo']['curip'],
      "nequipamento": equip['devinfo']['mac'],
      "nserie_rep": nil,
      "ativo": true,
      "integration_rep": false,
      "total_marcacoes": nil,
      "total_marcacoes_bobina": nil,
      "metragem_bobina_recomendada": nil,
      "cpf": nil,
      "app": false,
      "empresa_uid": 'a43bedds-ba77-4062-46c0-58f4444dad33'
    }
  end
end