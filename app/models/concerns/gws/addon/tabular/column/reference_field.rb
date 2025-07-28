module Gws::Addon::Tabular::Column::ReferenceField
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    cattr_accessor :use_reference_type, instance_accessor: false
    self.use_reference_type = true
  end
end
