module Facility::Addon
  module ImageFile
    extend ActiveSupport::Concern
    extend SS::Addon
    include Facility::Addon::Image::Model
  end
end
