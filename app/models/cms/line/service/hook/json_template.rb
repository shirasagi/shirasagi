module Cms::Line::Service::Hook
  class JsonTemplate < Base
    include Cms::Addon::Line::Service::JsonBody

    def type
      "json_template"
    end
  end
end
