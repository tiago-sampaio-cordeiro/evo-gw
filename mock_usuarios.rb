require 'faker'
require 'json'

Faker::Config.locale = 'pt-BR'

usuarios = []

100.times do
  cpf = Faker::IdNumber.brazilian_citizen_number(formatted: false).gsub(/\D/, '').to_i
  senha = rand(10**7..10**8 - 1) # Gera número entre 1000000 e 99999999
  nome = Faker::Name.first_name

  usuarios << [cpf, nome, senha]
end

File.open("mock_usuarios.json", "w") do |file|
  file.write(JSON.pretty_generate(usuarios))
end

puts "Mock salvo em mock_usuarios.json"
