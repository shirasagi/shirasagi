module Facility::Addon
  module IconSetting
    extend ActiveSupport::Concern
    extend SS::Addon
    include Facility::Addon::Image::Model
  end
end
