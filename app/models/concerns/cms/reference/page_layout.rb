module Cms::Reference
  module PageLayout
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      belongs_to :page_layout, class_name: "Cms::Layout"
      permit_params :page_layout_id
    end
  end
end
