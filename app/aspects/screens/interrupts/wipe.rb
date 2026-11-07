# frozen_string_literal: true

require "dry/monads"

module Terminus
  module Aspects
    module Screens
      module Interrupts
        # Renders device wipe screen.
        class Wipe
          include Deps["aspects.screens.faux", device_repository: "repositories.device"]
          include Dry::Monads[:result]

          def call device
            device_repository.update device.id, command: "screen_forward"
            Success faux.with(name: "screen_wiper.png")
          end
        end
      end
    end
  end
end
