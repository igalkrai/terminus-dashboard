# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Refines::Icalendar::Calendar do
  using described_class

  subject(:calendar) { Icalendar::Calendar.new }

  describe "#to_h" do
    let(:timezone) { {id: "", updated_at: nil, url: ""} }

    it "answers default hash" do
      expect(calendar.to_h).to eq(
        categories: [],
        color: "",
        description: [],
        events: [],
        images: [],
        ip_method: "",
        name: "VCALENDAR",
        product_identifier: "icalendar-ruby",
        refresh_interval: {},
        scale: "GREGORIAN",
        source: "",
        timezone:,
        uid: "",
        updated_at: nil,
        url: "",
        version: "2.0"
      )
    end

    context "with all attributes" do
      subject :calendar do
        Icalendar::Calendar.new.tap do |instance|
          instance.calscale = "JULIAN"
          instance.categories = %w[one two]
          instance.color = "blue"
          instance.description = "A description."
          instance.image = "https://test.io/test.png"
          instance.ip_method = "test"
          instance.last_modified = DateTime.new 2026, 9, 30
          instance.prodid = "test"
          instance.refresh_interval = Icalendar::Values::Duration.new nil
          instance.source = "https://test.io"
          instance.uid = "abc123"
          instance.url = "https://test.io"
          instance.version = "2.1"
        end
      end

      it "answers custom hash" do
        expect(calendar.to_h).to eq(
          categories: %w[one two],
          color: "blue",
          description: ["A description."],
          events: [],
          images: ["https://test.io/test.png"],
          ip_method: "test",
          name: "VCALENDAR",
          product_identifier: "test",
          refresh_interval: {
            days: 0,
            hours: 0,
            minutes: 0,
            past: false,
            seconds: 0,
            weeks: 0
          },
          scale: "JULIAN",
          source: "https://test.io",
          timezone:,
          uid: "abc123",
          updated_at: "2026-09-30T00:00:00+00:00",
          url: "https://test.io",
          version: "2.1"
        )
      end
    end
  end
end
