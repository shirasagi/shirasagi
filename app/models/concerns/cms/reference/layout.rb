module Cms::Reference
  module Layout
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      belongs_to :layout, class_name: "Cms::Layout"
      permit_params :layout_id
    end
  end
end
