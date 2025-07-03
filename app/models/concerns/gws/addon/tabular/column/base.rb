module Gws::Addon::Tabular::Column::Base
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Tabular::Column::Base

  included do
    cattr_accessor :use_index_state, :use_unique_state, instance_accessor: false
    self.use_index_state = true
    self.use_unique_state = true
  end

  module ClassMethods
    def as_plugin
      @plugin ||= Gws::Plugin.new(
        plugin_type: "tabular_column", path: self.name.underscore, module_key: 'gws/tabular', model_class: self)
    end
  end
end
