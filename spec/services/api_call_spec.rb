# spec/services/api_call_service_spec.rb
require 'spec_helper'
require_relative '../../app/services/api_call_service'

describe ApiCallService do
  before do
    stub_const('ENV', ENV.to_hash.merge('API_HOST' => 'http://fakeapi.com'))
  end

  describe '.authenticate_user' do
    it 'returns the request headers' do
      stub_request(:post, "http://fakeapi.com/v1/auth/sign_in")
        .with(body: { 'login' => 'admin', 'password' => 'diwbb00256' })
        .to_return(
          body: 'Success',
          headers: {
            'uid' => 'fake_uid',
            'access-token' => 'fake_token',
            'client' => 'fake_client'
          }
        )

      auth = described_class.authenticate_user
      expect(auth[:uid]).to eq('fake_uid')
      expect(auth[:access_token]).to eq('fake_token')
      expect(auth[:client]).to eq('fake_client')
    end

    it 'returns nil when the response body is empty' do
      stub_request(:post, "http://fakeapi.com/v1/auth/sign_in")
        .to_return(body: '', headers: {})

      expect(described_class.authenticate_user).to be_nil
    end

    it 'returns nil if any of the headers are empty' do
      stub_request(:post, "http://fakeapi.com/v1/auth/sign_in")
        .with(body: { 'login' => 'admin', 'password' => 'diwbb00256' })
        .to_return(
          body: 'Success',
          headers: {
            'uid' => '',
            'access-token' => 'fake_token',
            'client' => 'fake_client'
          }
        )

      auth = described_class.authenticate_user
      expect(auth).to be_nil
    end


  end
end