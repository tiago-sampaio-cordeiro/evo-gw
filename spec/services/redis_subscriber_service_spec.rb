require_relative '../../app/services/redis_subscriber_service'
require_relative '../../app/services/devices/sender'
require 'rspec'
require 'json'
require 'redis'
require 'logger'

RSpec.describe RedisSubscriberService do
  let(:channel) { 'test_channel' }
  let(:ws) { double('WebSocket') }
  let(:mutex) { Mutex.new }
  let(:logger) { double('Logger', info: nil, error: nil, warn: nil) }
  let(:redis_mock) { double('Redis') }
  let(:service) { described_class.new }

  before do
    # Zera estado compartilhado para não dar ruim entre testes
    described_class.instance_variable_set(:@subscribed_channels, {})
    described_class.instance_variable_set(:@mutex, Mutex.new)
    allow(Redis).to receive(:new).and_return(redis_mock)
  end

  describe '.subscribed?' do
    it 'retorna true se o canal estiver subscrito' do
      described_class.instance_variable_get(:@subscribed_channels)[channel] = true
      expect(described_class.subscribed?(channel)).to eq(true)
    end

    it 'retorna false se o canal não estiver subscrito' do
      expect(described_class.subscribed?(channel)).to eq(false)
    end
  end

  describe '.start' do
    it 'não inicia se já estiver subscrito' do
      described_class.instance_variable_get(:@subscribed_channels)[channel] = true
      expect(Thread).not_to receive(:new)
      described_class.start(channel: channel, ws: ws, mutex: mutex, logger: logger)
    end

    it 'inicia e processa mensagem JSON com cmd e args' do
      handler = nil

      allow(redis_mock).to receive(:subscribe).with(channel).and_yield(
        double('SubscriptionHandler').tap do |h|
          allow(h).to receive(:message) { |&block| handler = block }
        end
      )

      expect(Devices::Sender).to receive(:send).with(ws, 'test_command', 'arg1')

      thread = described_class.start(channel: channel, ws: ws, mutex: mutex, logger: logger)
      sleep 0.1

      handler.call(channel, { cmd: 'test_command', args: ['arg1'] }.to_json)
      thread.kill
    end

    it 'loga erro de JSON inválido' do
      handler = nil

      allow(redis_mock).to receive(:subscribe).with(channel).and_yield(
        double('SubscriptionHandler').tap do |h|
          allow(h).to receive(:message) { |&block| handler = block }
        end
      )

      expect(logger).to receive(:error).with(/Erro ao fazer parse/)

      thread = described_class.start(channel: channel, ws: ws, mutex: mutex, logger: logger)
      sleep 0.1

      handler.call(channel, 'invalid_json')
      thread.kill
    end

    it 'loga aviso se não houver comando no JSON' do
      handler = nil

      allow(redis_mock).to receive(:subscribe).with(channel).and_yield(
        double('SubscriptionHandler').tap do |h|
          allow(h).to receive(:message) { |&block| handler = block }
        end
      )

      expect(logger).to receive(:warn).with(/sem comando/)

      thread = described_class.start(channel: channel, ws: ws, mutex: mutex, logger: logger)
      sleep 0.1

      handler.call(channel, { foo: 'bar' }.to_json)
      thread.kill
    end

    it 'remove o canal do mapa após erro de conexão' do
      # Força Redis a lançar erro na conexão
      allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError.new("Simulated failure"))

      null_logger = Logger.new(IO::NULL)

      thread = described_class.start(channel: channel, ws: ws, mutex: mutex, logger: null_logger)

      # Espera a thread fazer a tentativa de conexão, falhar e limpar o canal
      attempts = 0
      subscribed = true
      while subscribed && attempts < 20
        sleep 0.1
        subscribed = described_class.subscribed?(channel)
        attempts += 1
      end

      expect(subscribed).to eq(false)

      thread.kill if thread&.alive?
    end

    it 'loga warning quando payload JSON não possui cmd' do
      handler = nil
      allow(redis_mock).to receive(:subscribe).with(channel).and_yield(
        double('SubscriptionHandler').tap do |h|
          allow(h).to receive(:message) { |&block| handler = block }
        end
      )

      expect(logger).to receive(:warn).with(/sem comando/)

      thread = described_class.start(channel: channel, ws: ws, mutex: mutex, logger: logger)
      sleep 0.1

      handler.call(channel, { foo: 'bar' }.to_json)
      thread.kill
    end

    it 'loga erro ao receber JSON inválido' do
      handler = nil
      allow(redis_mock).to receive(:subscribe).with(channel).and_yield(
        double('SubscriptionHandler').tap do |h|
          allow(h).to receive(:message) { |&block| handler = block }
        end
      )

      expect(logger).to receive(:error).with(/Erro ao fazer parse/)

      thread = described_class.start(channel: channel, ws: ws, mutex: mutex, logger: logger)
      sleep 0.1

      handler.call(channel, 'não é json')
      thread.kill
    end

    it 'loga erro quando Devices::Sender.send levanta exceção' do
      handler = nil
      allow(redis_mock).to receive(:subscribe).with(channel).and_yield(
        double('SubscriptionHandler').tap do |h|
          allow(h).to receive(:message) { |&block| handler = block }
        end
      )

      expect(Devices::Sender).to receive(:send).and_raise(StandardError.new('falha inesperada'))
      expect(logger).to receive(:error).with(/Erro ao processar comando/)

      thread = described_class.start(channel: channel, ws: ws, mutex: mutex, logger: logger)
      sleep 0.1

      handler.call(channel, { cmd: 'cmd' }.to_json)
      thread.kill
    end

    it 'retorna false para canal nil ou vazio' do
      expect(described_class.subscribed?(nil)).to be false
      expect(described_class.subscribed?('')).to be false
    end

    it 'retorna true se o canal está inscrito' do
      described_class.instance_variable_set(:@subscribed_channels, { channel => true })
      expect(described_class.subscribed?(channel)).to eq(true)
    end

    it 'retorna false se o canal não está inscrito' do
      described_class.instance_variable_set(:@subscribed_channels, { channel => true })
      expect(described_class.subscribed?('outro_canal')).to eq(false)
    end
  end
end
