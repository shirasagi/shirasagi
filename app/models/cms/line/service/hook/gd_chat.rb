module Cms::Line::Service::Hook
  class GdChat < Base
    include Cms::Addon::Line::Service::GdChat

    def type
      "gd_chat"
    end
  end
end
