module Cms::Line::Service::Hook
  class ImageMap < Base
    include Cms::Addon::Line::Service::ImageMap
    include Cms::Addon::Line::Service::Area

    def type
      "image_map"
    end
  end
end
