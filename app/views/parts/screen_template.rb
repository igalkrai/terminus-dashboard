# frozen_string_literal: true

require "hanami/view"

module Terminus
  module Views
    module Parts
      # The screen template presenter.
      class ScreenTemplate < Hanami::View::Part
        include Deps[:routes]

        def mode_label
          case mode
            when "text" then "Text"
            when "dither" then "Art"
            else "Unknown"
          end
        end
      end
    end
  end
end
