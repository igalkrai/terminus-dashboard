# frozen_string_literal: true

require "wholeable"

module Terminus
  module Aspects
    module Screens
      # A screen imitation when you need a screen that behaves like one but isn't.
      class Faux
        include Wholeable[:id, :label, :name, :uri, :width, :height]
        include Deps[:assets]

        def initialize(
          id: 0,
          label: "Faux",
          name: "faux",
          uri: "setup.svg",
          width: 800,
          height: 480,
          **
        )
          @id = id
          @label = label
          @name = name
          @uri = uri
          @width = width
          @height = height
          super(**)
        end

        def image_uri(**) = assets[uri].path

        def image_name_with_timestamp = name

        def popover_attributes = {id:, label:, uri: image_uri, width:, height:}
      end
    end
  end
end
