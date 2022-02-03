module Cms::Line::Service::Hook
  class FacilitySearch < Base
    include Cms::Addon::Line::Service::FacilitySearch

    def type
      "facility_search"
    end
  end
end
