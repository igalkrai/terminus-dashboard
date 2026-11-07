# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Extensions::Generators::Basic do
  subject(:generator) { described_class.new }

  describe "#call" do
    let :extension do
      Factory.structs[:extension, kind: "webhook", template: "<h1>{{extension.label}}</h1>"]
    end

    it "answers HTML" do
      data = {"extension" => {"label" => "Webhook"}}

      expect(generator.call(extension, context: data)).to be_success(
        "<html><head></head><body><h1>Webhook</h1></body></html>"
      )
    end
  end
end
