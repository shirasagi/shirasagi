module Cms::Addon
  module Line::Service::Area
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::Line::Area
  end
end
