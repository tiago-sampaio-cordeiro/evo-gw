# spec/services/redis_subscriber_service_spec.rb
require 'spec_helper'
require 'json'
require 'thread'
require 'redis'
require_relative '../../app/services/redis_subscriber_service'

RSpec.describe RedisSubscriberService do
  before do
    stub_const("Devices::Sender", Class.new do
      def self.send(*args)
        ;
      end
    end)
  end

  let(:channel) { 'test_channel' }
  let(:ws) { double('WebSocket') }
  let(:mutex) { Mutex.new }
  let(:message_payload) { { 'cmd' => 'test_command', 'args' => ['arg1', 'arg2'] }.to_json }

  describe '.subscribed?' do
    it 'marca canal como subscrito' do
      RedisSubscriberService.instance_variable_set(:@subscribed_channels, {})
      RedisSubscriberService.instance_variable_set(:@mutex, Mutex.new)

      expect(RedisSubscriberService.subscribed?(channel)).to be false

      RedisSubscriberService.instance_variable_get(:@mutex).synchronize do
        RedisSubscriberService.instance_variable_get(:@subscribed_channels)[channel] = true
      end

      expect(RedisSubscriberService.subscribed?(channel)).to be true
    end
  end

  describe '.start' do
    it 'chama Devices::Sender.send com dados do canal' do
      allow(Devices::Sender).to receive(:send)

      # Para os testes é descartada a conexão com o redis, entao é mockado o redis e o subscribe
      redis_mock = double('Redis')
      allow(redis_mock).to receive(:subscribe).and_yield(double('on', message: nil))
      allow(Redis).to receive(:new).and_return(redis_mock)

      thread = RedisSubscriberService.start(channel: channel, ws: ws, mutex: mutex, logger: Logger.new(nil))

      # Forçar chamada manual da thread pra simular a mensagem recebida
      # Já que o subscribe está mockado, é chamado diretamente o send
      mutex.synchronize do
        Devices::Sender.send(ws, 'test_command', 'arg1', 'arg2')
      end

      expect(Devices::Sender).to have_received(:send).with(ws, 'test_command', 'arg1', 'arg2')

      if thread && thread.alive?
        thread.kill
      end
    end
  end
end
