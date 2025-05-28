require 'rspec'
require 'json'
require 'logger'
require_relative '../../app/services/websocket_handler'

RSpec.describe WebSocketHandler do
  let(:app) { double('App', call: [200, {}, ['fallback']]) }
  let(:redis) { double('Redis', publish: true) }
  let(:connections) { {} }
  let(:mutex) { Mutex.new }
  let(:logger) { Logger.new(nil) }

  let(:config) do
    {
      redis: redis,
      connections: connections,
      mutex: mutex,
      logger: logger
    }
  end

  let(:env) do
    {
      'rack.input' => StringIO.new,
      'REMOTE_ADDR' => '127.0.0.1',
      'HTTP_CONNECTION' => 'Upgrade',
      'HTTP_UPGRADE' => 'websocket',
      'HTTP_SEC_WEBSOCKET_KEY' => 'x3JJHMbDL1EzLkh9GBhXDw==',
      'HTTP_SEC_WEBSOCKET_VERSION' => '13'
    }
  end

  subject { described_class.new(app, config) }

  before do
    allow(Faye::WebSocket).to receive(:websocket?).with(env).and_return(true)

    @fake_ws = double('Faye::WebSocket')
    allow(@fake_ws).to receive(:send)
    allow(Faye::WebSocket).to receive(:new).with(env).and_return(@fake_ws)

    allow(@fake_ws).to receive(:on) do |event, &block|
      @events ||= {}
      @events[event] = block
    end

    allow(@fake_ws).to receive(:rack_response).and_return([101, {}, []])
  end

  it 'inicializa conexão WebSocket e armazena no connections' do
    response = subject.call(env)

    # Simula evento :open
    @events[:open].call(double('Event'))

    expect(connections).to include(@fake_ws => nil)
    expect(response).to eq([101, {}, []])
  end

  it 'processa mensagem sendlog e publica no redis' do
    subject.call(env)

    message = {
      'sn' => '123',
      'cmd' => 'sendlog'
    }.to_json

    event = double('Event', data: message)

    @events[:message].call(event)

    expect(redis).to have_received(:publish).with('sendlog_channel', message)
    expect(connections['123']).to eq(@fake_ws)
  end

  it 'event error' do
    subject.call(env)

    error_event = double('Event', message: 'Erro Simulado')
    expect(@fake_ws).to receive(:on).with(:error).and_yield(error_event)

    subject.call(env)
  end

  it 'event close' do
    allow(logger).to receive(:info)

    subject.call(env)

    close_event = double('Event', code: 1000, reason: 'Normal Closure')

    @events[:close].call(close_event)

    expect(logger).to have_received(:info).with("Conexão encerrada. Código: 1000, Razão: Normal Closure")
  end

  context 'quando não é WebSocket' do
    it 'chama o app e retorna a resposta' do
      allow(Faye::WebSocket).to receive(:websocket?).with(env).and_return(false)

      expect(app).to receive(:call).with(env).and_return([200, {}, ['fallback']])

      response = subject.call(env)

      expect(response).to eq([200, {}, ['fallback']])
    end
  end
end
