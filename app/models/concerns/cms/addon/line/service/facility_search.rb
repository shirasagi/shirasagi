module Cms::Addon
  module Line::Service::FacilitySearch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      has_many :categories, class_name: "Cms::Line::FacilitySearch::Category", dependent: :destroy, inverse_of: :hook
      belongs_to :facility_node, class_name: "Facility::Node::Node"

      field :text_keys, type: SS::Extensions::Lines
      permit_params :facility_node_id, :text_keys
    end
  end
end
