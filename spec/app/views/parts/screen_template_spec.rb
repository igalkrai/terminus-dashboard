# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Views::Parts::ScreenTemplate do
  subject :part do
    described_class.new value: screen_template, rendering: Terminus::View.new.rendering
  end

  let(:screen_template) { Factory.structs[:screen_template] }

  describe "#mode_label" do
    it "answers text when text" do
      expect(part.mode_label).to eq("Text")
    end

    context "when dither" do
      let(:screen_template) { Factory.structs[:screen_template, mode: "dither"] }

      it "answers art" do
        expect(part.mode_label).to eq("Art")
      end
    end

    context "when unknown" do
      let(:screen_template) { Factory.structs[:screen_template, mode: "bogus"] }

      it "answers unknown" do
        expect(part.mode_label).to eq("Unknown")
      end
    end
  end
end
