require 'spec_helper'
require 'json'
require_relative '../../app/services/devices/evo'

RSpec.describe Devices do
  describe '.handle_reg' do
    let(:ws) { double('WebSocket') }

    context "quando recebe o comando 'reg'" do
      let(:message) do
        {
          "cmd" => "reg",
          "sn" => "ABC123"
        }
      end

      it "envia resposta de registro" do
        expect(ws).to receive(:send) do |json|
          response = JSON.parse(json)
          expect(response["ret"]).to eq("reg")
          expect(response["result"]).to be true
          expect(response).to have_key("cloudtime")
        end

        Devices.handle_reg(message, ws)
      end
    end

    context "quando recebe o comando 'sendlog'" do
      let(:message) do
        {
          "cmd" => "sendlog",
          "sn" => "XYZ789",
          "count" => 5,
          "logindex" => 123
        }
      end

      it "envia resposta de confirmação de logs" do
        expect(ws).to receive(:send) do |json|
          response = JSON.parse(json)
          expect(response["ret"]).to eq("sendlog")
          expect(response["result"]).to be true
          expect(response["count"]).to eq(5)
          expect(response["logindex"]).to eq(123)
          expect(response).to have_key("cloudtime")
        end

        Devices.handle_reg(message, ws)
      end
    end
  end
end
