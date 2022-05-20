module Cms::Addon
  module Line::DeliverCategory::ChildAge
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::Line::DeliverCondition::Model
  end
end
