module AuthenticateUserService
  def self.authenticate_user(login, password)
    uri = URI('http://api.961500-185090483.reviews.pontogestor.com/v1/auth/sign_in')
    res = Net::HTTP.post_form(uri, 'login' => 'admin', 'password' => 'diwbb00256')

    if res.body.nil? || res.body.empty?
      return nil
    else
      headers = res.to_hash

      return {
        uid: headers['uid']&.first,
        access_token: headers['access-token']&.first,
        client: headers['client']&.first
      }
    end
  end
end