# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Relations::Firmware, :db do
  subject(:relation) { Hanami.app["relations.firmware"] }

  describe "#version_descending" do
    it "orders by descending version" do
      one = Factory[:firmware, version: "0.0.1"]
      ten = Factory[:firmware, version: "0.0.10"]
      five = Factory[:firmware, version: "0.0.5"]

      expect(relation.version_descending.to_a).to eq([ten, five, one].map(&:to_h))
    end
  end

  describe "#with_model" do
    let(:firmware_a) { Factory[:firmware, version: "1.0.0"] }
    let(:firmware_b) { Factory[:firmware, version: "0.0.0"] }
    let(:model) { Factory[:model] }

    before do
      Factory[:firmware_model, firmware_id: firmware_b.id, model_id: model.id]
      Factory[:firmware_model, firmware_id: firmware_a.id, model_id: model.id]
    end

    it "answers all records by default, descending by version" do
      expect(relation.with_model.to_a).to match(
        [
          hash_including(id: firmware_a.id),
          hash_including(id: firmware_b.id)
        ]
      )
    end

    it "answers records by version" do
      expect(relation.with_model(version: "1.0.0").to_a).to match(
        [hash_including(id: firmware_a.id)]
      )
    end

    it "answers records by model" do
      Factory[:firmware_model]

      expect(relation.with_model(model_id: model.id).to_a).to match(
        [
          hash_including(id: firmware_a.id),
          hash_including(id: firmware_b.id)
        ]
      )
    end
  end
end
