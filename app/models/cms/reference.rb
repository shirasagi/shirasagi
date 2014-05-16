# coding: utf-8
module Cms::Reference
  module Layout
    extend ActiveSupport::Concern
    
    included do
      scope :layout_is, ->(layout) { where(layout_id: layout._id) }
      
      belongs_to :layout, class_name: "Cms::Layout"
      permit_params :layout_id
    end
  end
end
