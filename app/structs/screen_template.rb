# frozen_string_literal: true

module Terminus
  module Structs
    # The screen template struct.
    class ScreenTemplate < DB::Struct
      def export_attributes = {name:, label:, mode:}

      def screen_attributes = {template_id: id, name:, label:, mode:, content:}
    end
  end
end
