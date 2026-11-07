# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Screens::Faux do
  subject(:faux) { described_class.new }

  describe "#initialize" do
    it "answers default attributes" do
      expect(faux).to have_attributes(
        id: 0,
        label: "Faux",
        name: "faux",
        image_uri: Hanami.app[:assets]["setup.svg"].path,
        width: 800,
        height: 480
      )
    end

    it "answers custom attributes" do
      attributes = {id: 1, label: "Test", name: "test", uri: "blank.svg", width: 200, height: 100}

      expect(described_class[**attributes]).to have_attributes(
        id: 1,
        label: "Test",
        name: "test",
        image_uri: Hanami.app[:assets]["blank.svg"].path,
        width: 200,
        height: 100
      )
    end
  end

  describe "#image_uri" do
    it "answers asset path" do
      expect(faux.image_uri).to eq(Hanami.app[:assets]["setup.svg"].path)
    end
  end

  describe "#image_name_with_timestamp" do
    it "answers name without timestamp" do
      expect(faux.image_name_with_timestamp).to eq("faux")
    end
  end

  describe "#popover_attributes" do
    it "answers attributes" do
      expect(faux.popover_attributes).to eq(
        id: 0,
        label: "Faux",
        uri: Hanami.app[:assets]["setup.svg"].path,
        width: 800,
        height: 480
      )
    end
  end
end
