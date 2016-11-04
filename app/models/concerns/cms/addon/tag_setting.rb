module Cms::Addon::TagSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :st_tags, type: SS::Extensions::Words
    permit_params :st_tags
  end
end
