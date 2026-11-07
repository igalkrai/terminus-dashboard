# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Refines::Icalendar::Timezone do
  using described_class

  subject(:timezone) { Icalendar::Timezone.new }

  describe "#to_h" do
    it "answers default hash" do
      expect(timezone.to_h).to eq(id: "", url: "", updated_at: nil)
    end

    it "answers custom hash" do
      timezone = Icalendar::Timezone.new.tap do |instance|
        instance.tzid = "abc123"
        instance.tzurl = "https://test.io"
        instance.last_modified = DateTime.new 2026, 9, 30, 8, 0, 0
      end

      expect(timezone.to_h).to eq(
        id: "abc123",
        url: "https://test.io",
        updated_at: "2026-09-30T08:00:00+00:00"
      )
    end
  end
end
