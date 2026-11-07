# frozen_string_literal: true

module Terminus
  module Aspects
    module Screens
      module Converters
        # Converts to color image.
        class Color
          include Deps[mini_magick: "mini_magick.core"]
          include Dry::Monads[:result]

          def call mold
            convert mold
          rescue MiniMagick::Error => error
            Failure error.message
          end

          private

          def convert mold
            output_path = mold.output_path
            colors = mold.color_codes.map { "xc:#{it}" }
            type = mold.file_type

            mini_magick.convert do |tool|
              tool << mold.input_path.to_s
              tool.rotate mold.rotation if mold.rotatable?
              tool.resize "#{mold.dimensions}!"
              tool.crop mold.crop if mold.cropable?
              tool.colorspace "HSV"
              tool.channel "B"
              tool.sigmoidal_contrast "5,50%"
              tool.merge! ["+channel"]
              tool.merge! [
                "(",
                "-size",
                "1x1",
                *colors,
                "+channel",
                "+append",
                "+write",
                "mpr:palette",
                "+delete",
                ")"
              ]
              tool.dither "FloydSteinberg"
              tool.remap "mpr:palette"
              tool.colorspace "sRGB"

              if type == "png"
                tool.type "Palette"
                tool.define "png:compression-level=9"
              elsif type == "webp" && mold.lossless?
                tool.define "webp:lossless=true"
              end

              tool << "#{type}:#{output_path}"
            end

            Success output_path
          end
        end
      end
    end
  end
end
