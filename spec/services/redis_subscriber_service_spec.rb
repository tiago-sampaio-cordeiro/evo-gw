require 'spec_helper'
require 'json'
require 'logger'
require 'redis'
require_relative '../../app/services/redis_subscriber_service'
require_relative '../../app/services/devices/sender'

RSpec.describe RedisSubscriberService do
  let(:channel) { 'test_channel' }
  let(:ws) { double('WebSocket') }
  let(:mutex) { Mutex.new }
  let(:subscribed_channels) { {} }
  let(:logger) { instance_double(Logger, info: nil, debug: nil, warn: nil, error: nil) }
  let(:message) { { cmd: 'noop' }.to_json }
  let(:redis_mock) { double('Redis', subscribe: nil) }

  before do
    allow(Redis).to receive(:new).and_return(redis_mock)
    allow(redis_mock).to receive(:subscribe).and_yield(subscription_callback)
    allow(Devices::Sender).to receive(:send)
  end

  let(:subscription_callback) do
    double('SubscriptionCallback').tap do |cb|
      allow(cb).to receive(:message).and_yield(channel, message)
    end
  end

  context 'quando o canal já está inscrito' do
    it 'não inicia nova thread' do
      mutex.synchronize { subscribed_channels[channel] = true }

      result = RedisSubscriberService.start(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      expect(result).to be_nil
    end
  end

  context 'quando recebe mensagem válida com comando' do
    let(:message) { { cmd: 'notify', args: ['arg1'] }.to_json }

    it 'envia comando via Devices::Sender' do
      thread = RedisSubscriberService.start(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread.join

      expect(Devices::Sender).to have_received(:send).with(ws, 'notify', 'arg1')
      expect(logger).to have_received(:debug).with(/Mensagem recebida/)
    end
  end

  context 'quando recebe mensagem JSON inválida' do
    let(:message) { 'INVALID_JSON' }

    it 'loga erro de parse' do
      thread = RedisSubscriberService.start(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread.join

      expect(logger).to have_received(:error).with(/Erro ao fazer parse/)
    end
  end

  context 'quando recebe JSON sem comando' do
    let(:message) { { something_else: true }.to_json }

    it 'loga warning e ignora' do
      thread = RedisSubscriberService.start(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread.join

      expect(logger).to have_received(:warn).with(/Payload recebido sem comando/)
      expect(Devices::Sender).not_to have_received(:send)
    end
  end

  context 'quando Devices::Sender.send lança exceção' do
    let(:message) { { cmd: 'fail', args: [] }.to_json }

    before do
      allow(Devices::Sender).to receive(:send).and_raise(StandardError.new('FAIL'))
    end

    it 'loga erro e não interrompe' do
      thread = RedisSubscriberService.start(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread.join

      expect(logger).to have_received(:error).with(/Erro ao processar comando/)
    end
  end

  context 'quando Redis não conecta' do
    before do
      allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError.new('connection down'))
    end

    let(:message) { { cmd: 'noop' }.to_json }

    it 'loga erro de conexão' do
      thread = RedisSubscriberService.start(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread.join

      expect(logger).to have_received(:error).with(/Falha ao conectar ao Redis/)
    end
  end
end
