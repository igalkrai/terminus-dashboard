# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Refines::Icalendar::Alarm do
  using described_class

  subject(:alarm) { Icalendar::Alarm.new }

  describe "#to_h" do
    it "answers default hash" do
      expect(alarm.to_h).to eq(
        action: "DISPLAY",
        attachments: [],
        attendees: [],
        description: "",
        duration: {},
        repeat: 0,
        summary: "",
        trigger: {}
      )
    end

    it "answers custom hash" do
      alarm = Icalendar::Alarm.new.tap do |instance|
        instance.attach = "https://test.io/test.png"
        instance.attendee = "mailto:test@test.io"
        instance.description = "A description."
        instance.duration = Icalendar::Values::Duration.new nil
        instance.repeat = 3
        instance.summary = "A summary."
        instance.trigger = Icalendar::Values::Duration.new nil
      end

      expect(alarm.to_h).to eq(
        action: "DISPLAY",
        attachments: ["https://test.io/test.png"],
        attendees: ["mailto:test@test.io"],
        description: "A description.",
        duration: {
          days: 0,
          hours: 0,
          minutes: 0,
          past: false,
          seconds: 0,
          weeks: 0
        },
        repeat: 3,
        summary: "A summary.",
        trigger: {
          days: 0,
          hours: 0,
          minutes: 0,
          past: false,
          seconds: 0,
          weeks: 0
        }
      )
    end
  end
end
