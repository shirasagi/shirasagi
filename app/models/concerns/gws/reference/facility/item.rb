module Gws::Reference::Facility::Item
  extend ActiveSupport::Concern
  extend SS::Translation

  attr_accessor :cur_facility

  included do
    belongs_to :facility, class_name: 'Gws::Facility::Item'

    before_validation :set_facility_id, if: ->{ @cur_facility }

    scope :facility, ->(facility) { where(facility_id: facility.id) }
  end

  private

  def set_facility_id
    return unless @cur_facility
    self.facility_id = @cur_facility.id
  end
end
