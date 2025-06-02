require 'ostruct'

FactoryBot.define do
  factory :equipment, class: OpenStruct do
    sequence(:id) { |n| n }
    name { "Equipamento #{id}" }
    status { "ativo" }

    initialize_with { new(attributes) }
  end
end
