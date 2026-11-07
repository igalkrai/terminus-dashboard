# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Serializers::Firmware, :db do
  subject(:serializer) { described_class.new record }

  let(:record) { Factory.structs[:firmware, :with_attachment, **attributes] }

  let :attributes do
    {
      id: 1,
      version: "0.0.0",
      created_at: "2025-01-01T10:10:10+0000",
      updated_at: "2025-01-01T10:10:10+0000"
    }
  end

  describe "#to_h" do
    it "answers hash with attachment attributes" do
      expect(serializer.to_h).to eq(
        id: 1,
        version: "0.0.0",
        file_name: "0.0.0.bin",
        mime_type: "application/octet-stream",
        size: 4,
        uri: "memory://abc123.bin",
        model_ids: [],
        created_at: "2025-01-01T10:10:10+0000",
        updated_at: "2025-01-01T10:10:10+0000"
      )
    end

    it "answers with model IDs" do
      model = Factory[:model]
      record = Factory[:firmware, :with_attachment, **attributes]
      serializer = described_class.new Factory.structs[:firmware, **attributes]

      Factory[:firmware_model, firmware_id: record.id, model_id: model.id]

      expect(serializer.to_h).to eq(
        id: 1,
        version: "0.0.0",
        file_name: "0.0.0.bin",
        model_ids: [model.id],
        created_at: "2025-01-01T10:10:10+0000",
        updated_at: "2025-01-01T10:10:10+0000"
      )
    end

    it "answers hash without attachment" do
      serializer = described_class.new Factory.structs[:firmware, **attributes]

      expect(serializer.to_h).to eq(
        id: 1,
        version: "0.0.0",
        file_name: "0.0.0.bin",
        model_ids: [],
        created_at: "2025-01-01T10:10:10+0000",
        updated_at: "2025-01-01T10:10:10+0000"
      )
    end
  end
end
