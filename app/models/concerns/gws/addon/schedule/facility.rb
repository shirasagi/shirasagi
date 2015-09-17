module Gws::Addon::Schedule::Facility
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :facilities, class_name: "Gws::Facility"

    permit_params facility_ids: []

    scope :facility, ->(item) { where facility_ids: item.id }
  end
end
