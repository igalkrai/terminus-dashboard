# frozen_string_literal: true

module Terminus
  module Structs
    # The palette struct.
    class Palette < DB::Struct
      def screen_attributes = {palette_name: name, grays:, color_codes: colors}
    end
  end
end
