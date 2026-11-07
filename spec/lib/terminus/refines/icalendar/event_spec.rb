# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Refines::Icalendar::Event do
  using described_class

  subject :event do
    Icalendar::Event.new.tap do |event|
      event.dtstamp = DateTime.new 2026, 9, 30
      event.uid = "abc123"
    end
  end

  describe "#to_h" do
    let :alarm do
      {
        action: "DISPLAY",
        attachments: [],
        attendees: [],
        description: "",
        duration: {},
        repeat: 0,
        summary: "",
        trigger: {}
      }
    end

    it "answers default hash" do
      expect(event.to_h).to eq(
        alarm:,
        attachments: [],
        attendees: [],
        categories: [],
        classification: "",
        color: "",
        comments: [],
        contacts: [],
        created_at: nil,
        description: "",
        duration: {},
        end_at: nil,
        exceptions: [],
        geocoordinates: [],
        images: [],
        location: "",
        name: "VEVENT",
        organizer: "",
        priority: 0,
        recurrence_id: nil,
        recurrence_rule: [],
        recurrences: [],
        related_to: [],
        request_status: [],
        resources: [],
        sequence: 0,
        start_at: nil,
        status: "",
        summary: "",
        synced_at: "2026-09-30T00:00:00+00:00",
        time_transparency: "",
        uid: "abc123",
        updated_at: nil,
        url: ""
      )
    end

    context "with all attributes" do
      subject :event do
        Icalendar::Event.new.tap do |instance|
          instance.attach = "https://test.io/test.pdf"
          instance.attendee = ["mailto:a@test.io", "mailto:b@test.io"]
          instance.categories = %w[Work Meeting]
          instance.color = "blue"
          instance.comment = %w[One. Two.]
          instance.contact = %w[mailto:a@test.io mailto:b@test.io]
          instance.created = DateTime.new 2026, 9, 29, 8, 0, 0
          instance.description = "A description."
          instance.dtend = DateTime.new 2026, 10, 1, 10, 0, 0
          instance.dtstamp = DateTime.new 2026, 9, 30
          instance.dtstart = DateTime.new 2026, 10, 1, 9, 0, 0
          instance.exdate = [DateTime.new(2026, 10, 15, 9, 0, 0)]
          instance.geo = [37.849167, -105.4945]
          instance.image = "https://test.io/test.png"
          instance.ip_class = "PUBLIC"
          instance.last_modified = DateTime.new 2026, 9, 29, 9, 30, 0
          instance.location = "Room 5"
          instance.organizer = "mailto:a@test.io"
          instance.priority = 5
          instance.rdate = [DateTime.new(2026, 10, 22, 9, 0, 0)]
          instance.recurrence_id = DateTime.new 2026, 10, 8, 9, 0, 0
          instance.related_to = ["abc124"]
          instance.request_status = ["2.0;Success"]
          instance.resources = %w[Projector Whiteboard]
          instance.rrule = "FREQ=WEEKLY;COUNT=10"
          instance.sequence = 2
          instance.status = "CONFIRMED"
          instance.summary = "Test"
          instance.transp = "OPAQUE"
          instance.uid = "abc123"
          instance.url = "https://test.io/events/1"
        end
      end

      it "answers custom hash" do
        expect(event.to_h).to eq(
          alarm:,
          attachments: ["https://test.io/test.pdf"],
          attendees: ["mailto:a@test.io", "mailto:b@test.io"],
          categories: %w[Work Meeting],
          classification: "PUBLIC",
          color: "blue",
          comments: %w[One. Two.],
          contacts: %w[mailto:a@test.io mailto:b@test.io],
          created_at: "2026-09-29T08:00:00+00:00",
          description: "A description.",
          duration: {},
          end_at: "2026-10-01T10:00:00+00:00",
          exceptions: ["2026-10-15T09:00:00+00:00"],
          geocoordinates: [37.849167, -105.4945],
          images: ["https://test.io/test.png"],
          location: "Room 5",
          name: "VEVENT",
          organizer: "mailto:a@test.io",
          priority: 5,
          recurrence_id: "2026-10-08T09:00:00+00:00",
          recurrence_rule: [
            {
              by_day: nil,
              by_hour: nil,
              by_minute: nil,
              by_month: nil,
              by_month_day: nil,
              by_second: nil,
              by_set_position: nil,
              by_week_number: nil,
              by_year_day: nil,
              count: 10,
              frequency: "WEEKLY",
              interval: nil,
              until: nil,
              week_start: nil
            }
          ],
          recurrences: ["2026-10-22T09:00:00+00:00"],
          related_to: ["abc124"],
          request_status: ["2.0;Success"],
          resources: %w[Projector Whiteboard],
          sequence: 2,
          start_at: "2026-10-01T09:00:00+00:00",
          status: "CONFIRMED",
          summary: "Test",
          synced_at: "2026-09-30T00:00:00+00:00",
          time_transparency: "OPAQUE",
          uid: "abc123",
          updated_at: "2026-09-29T09:30:00+00:00",
          url: "https://test.io/events/1"
        )
      end
    end
  end
end
