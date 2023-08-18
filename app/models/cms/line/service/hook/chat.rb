module Cms::Line::Service::Hook
  class Chat < Base
    include Cms::Addon::Line::Service::Chat

    def type
      "chat"
    end
  end
end
