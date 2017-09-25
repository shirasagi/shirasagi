module Gws::Addon::Schedule::FacilityCustomField
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :main_facility, class_name: 'Gws::Facility::Item'
  end
end
