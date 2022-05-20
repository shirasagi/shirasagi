module Cms::Line::Service::Hook
  class Api < Base
    include Cms::Addon::Line::Service::Api

    def type
      "api"
    end
  end
end
