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
    allow(Devices::Sender).to receive(:send)
  end

  context 'quando o canal já está inscrito' do
    it 'não inicia nova thread' do
      mutex.synchronize { subscribed_channels[channel] = true }

      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      result = service.start
      expect(result).to be_nil
    end
  end

  context 'quando recebe mensagem válida com comando' do
    let(:message) { { cmd: 'notify', args: ['arg1'] }.to_json }

    it 'envia comando via Devices::Sender' do
      allow(redis_mock).to receive(:subscribe).and_yield(
        double('SubscriptionBlock').tap do |cb|
          allow(cb).to receive(:message).and_yield(channel, message)
        end
      )

      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread = service.start
      thread.join(0.1)

      expect(Devices::Sender).to have_received(:send).with(ws, 'notify', 'arg1')
      expect(logger).to have_received(:debug).with(/Mensagem recebida/)
    end
  end

  context 'quando recebe mensagem JSON inválida' do
    let(:message) { 'INVALID_JSON' }

    it 'loga erro de parse' do
      allow(redis_mock).to receive(:subscribe).and_yield(
        double('SubscriptionBlock').tap do |cb|
          allow(cb).to receive(:message).and_yield(channel, message)
        end
      )

      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread = service.start
      thread.join(0.1)

      expect(logger).to have_received(:error).with(/Erro ao fazer parse/)
    end
  end

  context 'quando recebe JSON sem comando' do
    let(:message) { { something_else: true }.to_json }

    it 'loga warning e ignora' do
      allow(redis_mock).to receive(:subscribe).and_yield(
        double('SubscriptionBlock').tap do |cb|
          allow(cb).to receive(:message).and_yield(channel, message)
        end
      )

      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread = service.start
      thread.join(0.1)

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
      allow(redis_mock).to receive(:subscribe).and_yield(
        double('SubscriptionBlock').tap do |cb|
          allow(cb).to receive(:message).and_yield(channel, message)
        end
      )

      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread = service.start
      thread.join(0.1)

      expect(logger).to have_received(:error).with(/Erro ao processar comando/)
    end
  end

  context 'quando Redis não conecta' do
    before do
      allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError.new('connection down'))
    end

    let(:message) { { cmd: 'noop' }.to_json }

    it 'loga erro de conexão' do
      allow(redis_mock).to receive(:subscribe).and_yield(
        double('SubscriptionBlock').tap do |cb|
          allow(cb).to receive(:message).and_yield(channel, message)
        end
      )

      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread = service.start
      thread.join(0.1)

      expect(logger).to have_received(:error).with(/Falha ao conectar ao Redis/)
    end
  end

  class TestLogger
    attr_reader :messages

    def info(msg)
      @messages << "INFO: #{msg}"
    end

    def warn(msg)
      @messages << "WARN: #{msg}"
    end

    def debug(msg)
      @messages << "DEBUG: #{msg}"
    end

    def initialize
      @messages = []
    end

    def error(msg)
      @messages << msg
    end
  end

  context 'quando ocorre um erro inesperado no Redis' do
    let(:fake_error) { StandardError.new('erro aleatório') }
    let(:test_logger) { TestLogger.new }

    before do
      allow(Kernel).to receive(:sleep).with(2)
      allow(Redis).to receive(:new).and_raise(fake_error)
    end

    it 'loga o erro e tenta reconectar' do
      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: test_logger,
        subscribed_channels: subscribed_channels
      )
      thread = service.start
      thread.join(0.1)

      expect(thread).to be_a(Thread)
      expect(test_logger.messages.any? { |m| m =~ /Erro no Redis \(canal: #{channel}\): erro aleatório/ }).to be true
    end
  end

  context 'quando uma exceção é lançada fora do Devices::Sender' do
    let(:message) { { cmd: 'unexpected_error', args: [] }.to_json }

    before do
      allow(redis_mock).to receive(:subscribe).and_yield(
        double('SubscriptionBlock').tap do |cb|
          allow(cb).to receive(:message).and_yield(channel, message)
        end
      )

      allow(Devices::Sender).to receive(:send).and_raise(RuntimeError, 'Erro inesperado')
    end

    it 'captura e loga o erro' do
      service = RedisSubscriberService.new(
        channel: channel,
        ws: ws,
        mutex_subscribed_channels: mutex,
        logger: logger,
        subscribed_channels: subscribed_channels
      )

      thread = service.start
      thread.join(0.1)

      expect(logger).to have_received(:error).with(/Erro ao processar comando/)
    end
  end
end
