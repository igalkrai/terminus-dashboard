# frozen_string_literal: true

module Terminus
  module Relations
    # The firmware relation.
    class Firmware < DB::Relation
      schema :firmware, infer: true do
        associations do
          has_many :firmware_models, relation: :firmware_model
          has_many :models, through: :firmware_model, relation: :model, as: :models
        end
      end

      def version_descending
        order Sequel.desc(Sequel.function(:string_to_array, :version, ".").cast("int[]"))
      end

      def with_model(**)
        join(:firmware_model, firmware_id: :id).join(:model, id: firmware_model[:model_id])
                                               .where(**)
                                               .version_descending
                                               .combine(:models)
      end
    end
  end
end
