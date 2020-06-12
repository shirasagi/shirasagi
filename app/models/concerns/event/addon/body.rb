module Event::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :schedule, type: String
      field :venue, type: String
      field :content, type: String
      field :cost, type: String
      field :related_url, type: String
      field :contact, type: String

      embeds_ids :facilities, class_name: "Facility::Node::Page"
      permit_params facility_ids: []
      permit_params :schedule, :venue, :content, :cost, :related_url, :contact
    end
  end
end
