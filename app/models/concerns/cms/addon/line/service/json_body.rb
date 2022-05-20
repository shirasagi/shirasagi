module Cms::Addon
  module Line::Service::JsonBody
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::Line::JsonBody
  end
end
