# auto_register: false
# frozen_string_literal: true

require "core"

# Patches Hanami's universal logger to work with Cogger.
module UniversalLoggerPatch
  DEFAULTS = {
    verb: nil,
    status: nil,
    elapsed: nil,
    elapsed_unit: nil,
    ip: nil,
    path: nil,
    length: nil,
    db: nil,
    query: nil
  }.freeze

  def _log_structured method, message, payload
    tags = _current_tags
    block_content = block_given? ? yield : message

    logger.formatter = case tags
                         in [:rack] then tags.delete :rack
                         in [:sql] then tags.delete :sql
                         else Hanami.env == :development ? :emoji : :json
                       end

    unless block_content.is_a? Hash
      message = block_content
      block_content = Core::EMPTY_HASH
    end

    logger.public_send method, message, tags:, **DEFAULTS, **payload, **block_content
  end
end

Hanami::UniversalLogger.prepend UniversalLoggerPatch
