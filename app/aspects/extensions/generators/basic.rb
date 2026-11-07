# frozen_string_literal: true

require "core"
require "dry/monads"

module Terminus
  module Aspects
    module Extensions
      module Generators
        # Uses Liquid template to render basic data.
        class Basic
          include Deps[renderer: "superfluid.sanitize"]
          include Dry::Monads[:result]

          def call extension, context: Core::EMPTY_HASH
            Success renderer.call(extension.template, context)
          end
        end
      end
    end
  end
end
