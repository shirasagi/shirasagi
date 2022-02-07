module Cms::Addon
  module Line::Service::FacilitySearch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      has_many :categories, class_name: "Cms::Line::FacilitySearch::Category", dependent: :destroy, inverse_of: :hook
    end
  end
end
