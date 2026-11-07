# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Screens::Interrupts::Wipe, :db do
  subject(:interrupter) { described_class.new }

  describe "#call" do
    let(:device) { Factory[:device, command: "screen_wipe"] }

    it "answers screen" do
      expect(interrupter.call(device).success).to have_attributes(name: "screen_wiper.png")
    end

    it "answers reverts to next screen command afterwards" do
      interrupter.call device
      expect(Terminus::Repositories::Device.new.find(device.id).command).to eq("screen_forward")
    end
  end
end
