# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Structs::Palette do
  subject(:palette) { Factory.structs[:palette, name: "bw", grays: 2, colors: %w[#000000 #FFFFFF]] }

  describe "#screen_attributes" do
    it "answers attributes" do
      expect(palette.screen_attributes).to eq(
        palette_name: "bw",
        grays: 2,
        color_codes: ["#000000", "#FFFFFF"]
      )
    end
  end
end
