# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Actions::Firmware::Create, :db do
  subject(:action) { described_class.new }

  describe "#call" do
    let(:model) { Factory[:model] }

    it "creates firmware" do
      repository = Terminus::Repositories::Firmware.new

      action.call firmware: {
                    version: "1.2.3",
                    attachment: {
                      name: "test",
                      type: "attachment",
                      head: "test",
                      filename: "test.bin",
                      tempfile: StringIO.new("test")
                    }
                  },
                  model_ids: [model.id]

      expect(repository.find_by(version: "1.2.3")).to be_a(Terminus::Structs::Firmware)
    end

    it "includes version error" do
      response = action.call firmware: {
                               version: nil,
                               attachment: {
                                 name: "test",
                                 type: "attachment",
                                 head: "test",
                                 filename: "test.bin",
                                 tempfile: StringIO.new("test")
                               }
                             },
                             model_ids: [model.id]

      expect(response.body.first).to match(/version.+must be filled/m)
    end

    it "includes model IDs error" do
      response = action.call firmware: {
                               version: "1.2.3",
                               attachment: {
                                 name: "test",
                                 type: "attachment",
                                 head: "test",
                                 filename: "test.bin",
                                 tempfile: StringIO.new("test")
                               }
                             },
                             model_ids: []

      expect(response.body.first).to match(/models.+must be filled/im)
    end
  end
end
