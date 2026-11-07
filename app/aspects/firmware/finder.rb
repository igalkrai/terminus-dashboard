# frozen_string_literal: true

require "dry/monads"
require "initable"

module Terminus
  module Aspects
    module Firmware
      # Finds firmware based on model ID and related attributes.
      class Finder
        include Deps[:i18n, firmware_repository: "repositories.firmware"]
        include Dry::Monads[:result]

        def call version = nil, model_id:
          query = {model_id:, version:}.compact!

          firmware_repository.where(**query).first.then do |firmware|
            return Success firmware if firmware

            Failure(i18n.translate("aspects.firmware.finder.missing", version:, model_id:))
          end
        end
      end
    end
  end
end
