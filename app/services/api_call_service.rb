require 'dotenv/load'

module ApiCallService
  def self.authenticate_user
    uri = URI(ENV['API_HOST'])
    path = '/v1/auth/sign_in'
    full_path = uri + path
    res = Net::HTTP.post_form(full_path, 'login' => 'admin', 'password' => 'diwbb00256')

    return nil if res.body.nil? || res.body.empty?

    headers = res.to_hash
    uid = headers['uid']&.first
    token = headers['access-token']&.first
    client = headers['client']&.first

    return nil if uid.to_s.strip.empty? || token.to_s.strip.empty? || client.to_s.strip.empty?

    {
      uid: uid,
      access_token: token,
      client: client
    }
  end


  def self.equipment
    auth_data = authenticate_user

    # Faz a requisição GET autenticada
    uri = URI(ENV['API_HOST'])
    path = '/v1/equipamentos'
    full_path = uri + path

    req = Net::HTTP::Get.new(full_path)
    req['uid'] = auth_data[:uid]
    req['access-token'] = auth_data[:access_token]
    req['client'] = auth_data[:client]

    # Executa a requisição
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    res.body
  end
end