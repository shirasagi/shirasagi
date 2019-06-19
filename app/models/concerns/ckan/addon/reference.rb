module Ckan::Addon
  module Reference
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      belongs_to :exporter, class_name: 'Opendata::Harvest::Exporter'
      permit_params :exporter_id
      validates :exporter_id, presence: true
    end
  end
end
