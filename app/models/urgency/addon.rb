# coding: utf-8
module Urgency::Addon
  module Layout
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 10

    included do
      field :urgency_default_layout_id, type: Integer
      permit_params :urgency_default_layout_id

      validates_presence_of :urgency_default_layout_id

      public
        def urgency_default_layout
          Cms::Layout.find(self[:urgency_default_layout_id].to_i) rescue return nil
        end
    end
  end
end
