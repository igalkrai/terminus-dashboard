# frozen_string_literal: true

require "icalendar"

module Terminus
  module Refines
    module Icalendar
      # Modifies and enhances default iCalendar alarm behavior.
      module Alarm
        refine ::Icalendar::Alarm do
          def to_h
            {
              action: action.to_s,
              attendees: attendee.map(&:to_s),
              trigger: trigger.to_h,
              description: description.to_s,
              summary: summary.to_s,
              duration: duration.to_h,
              repeat: repeat.to_i,
              attachments: attach.map(&:to_s)
            }
          end
        end
      end
    end
  end
end
