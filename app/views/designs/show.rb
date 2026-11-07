# frozen_string_literal: true

module Terminus
  module Views
    module Designs
      # The show view.
      class Show < View
        decorate :template, as: Parts::ScreenTemplate
      end
    end
  end
end
