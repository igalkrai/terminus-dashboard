# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Firmware::Finder, :db do
  subject(:finder) { described_class.new }

  describe "#call" do
    let(:model) { Factory[:model] }
    let(:firmware) { Factory[:firmware, version: "1.0.0"] }
    let(:firmware_model) { Factory[:firmware_model, firmware_id: firmware.id, model_id: model.id] }

    it "answers latest version when version is missing" do
      firmware_model
      expect(finder.call(model_id: model.id)).to match(Success(having_attributes(id: firmware.id)))
    end

    it "answers specific version when version is present" do
      other = Factory[:firmware, version: "0.0.0"]
      Factory[:firmware_model, firmware_id: other.id, model_id: model.id]

      expect(finder.call("0.0.0", model_id: model.id)).to match(
        Success(having_attributes(id: other.id))
      )
    end

    it "answers failure when not found" do
      expect(finder.call(model_id: 666)).to be_failure(
        "Unable to find firmware with version () and model ID (666)."
      )
    end
  end
end
