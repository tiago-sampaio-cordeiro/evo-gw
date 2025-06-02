require 'rspec'
require 'json'
require 'logger'
require_relative '../../app/services/devices/sender'


RSpec.describe Devices::Sender do
  let(:ws) { double('WebSocket') }

  describe '.send' do
    it 'envia user_list corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'getuserlist',
                                          stn: true
                                        }.to_json)

      described_class.send(ws, 'user_list')
    end

    it 'envia user_info corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'getuserinfo',
                                          enrollid: '123',
                                          backupnum: 10
                                        }.to_json)

      described_class.send(ws, 'user_info', '123')
    end

    it 'envia set_user_info corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'setuserinfo',
                                          enrollid: 123,
                                          name: 'Tiago',
                                          backupnum: 10,
                                          record: 'registro'
                                        }.to_json)

      described_class.send(ws, 'set_user_info', '123', 'Tiago', 'registro')
    end

    it 'envia delete_user corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'deleteuser',
                                          enrollid: '123',
                                          backupnum: 10
                                        }.to_json)

      described_class.send(ws, 'delete_user', '123')
    end

    it 'envia get_username corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'getusername',
                                          enrollid: '123'
                                        }.to_json)

      described_class.send(ws, 'username', '123')
    end

    it 'envia set_username corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'setusername',
                                          count: 1,
                                          record: [{
                                                     enrollid: '123',
                                                     name: 'Tiago'
                                                   }]
                                        }.to_json)

      described_class.send(ws, 'set_username', '123', 'Tiago')
    end

    it 'envia enable_user corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'enableuser',
                                          enrollid: '123',
                                          enflag: 1
                                        }.to_json)

      described_class.send(ws, 'enable_user', '123', 1)
    end

    it 'envia clean_user corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'cleanuser'
                                        }.to_json)

      described_class.send(ws, 'clean_user')
    end

    it 'envia get_new_log corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'getnewlog',
                                          stn: true
                                        }.to_json)

      described_class.send(ws, 'get_new_log')
    end

    it 'envia get_all_log corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'getalllog',
                                          stn: true,
                                          from: '2023-01-01',
                                          to: '2023-12-31'
                                        }.to_json)

      described_class.send(ws, 'get_all_log', '2023-01-01', '2023-12-31')
    end

    it 'envia clean_log corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'cleanlog'
                                        }.to_json)

      described_class.send(ws, 'clean_log')
    end

    it 'envia initsys corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'initsys'
                                        }.to_json)

      described_class.send(ws, 'initsys')
    end

    it 'envia reboot corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'reboot'
                                        }.to_json)

      described_class.send(ws, 'reboot')
    end

    it 'envia clean_admin corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'cleanadmin'
                                        }.to_json)

      described_class.send(ws, 'clean_admin')
    end

    it 'envia set_time corretamente' do
      expect(ws).to receive(:send).with({
                                          cmd: 'settime',
                                          cloudtime: '2024-01-01T00:00:00Z'
                                        }.to_json)

      described_class.send(ws, 'set_time', '2024-01-01T00:00:00Z')
    end

    it 'log erro se comando é desconhecido' do
      expect(ws).not_to receive(:send)
      expect { described_class.send(ws, 'comando_inexistente') }
        .to output(/Comando desconhecido/).to_stdout_from_any_process
    end
  end
end

RSpec.describe Devices::Sender do
  let(:ws) { double('WebSocket') }

  before do
    # captura logs pra verificar erros
    allow(ws).to receive(:send)
  end

  describe '.send' do
    it 'loga erro quando comando é desconhecido' do
      expect(Devices::Sender::LOGGER).to receive(:error).with('Comando desconhecido: comando_invalido')
      described_class.send(ws, 'comando_invalido')
    end

    context 'quando ws.send lança exceção' do
      before do
        allow(ws).to receive(:send).and_raise(StandardError.new('ws caiu'))
      end

      it 'loga erro ao tentar enviar comando' do
        expect(Devices::Sender::LOGGER).to receive(:error).with(/ws caiu/)
        described_class.send(ws, 'reboot')
      end
    end

    context 'com argumentos insuficientes' do
      it 'lança ArgumentError em set_user_info se faltar argumento' do
        expect {
          described_class.send(ws, 'set_user_info', 'usuario') # falta args
        }.to raise_error(ArgumentError)
      end
    end
  end
end
