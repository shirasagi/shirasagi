require "sprockets"
require 'sprockets/erb_processor'

module Sprockets
  class ERBProcessor
    alias call_without_shirasagi call

    def call(input)
      # always run in ja to transpile assets
      I18n.with_locale(I18n.default_locale) do
        call_without_shirasagi(input)
      end
    end
  end
end
