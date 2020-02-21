module Cms::Addon
  module ChildList
    extend ActiveSupport::Concern
    extend SS::Addon
    include ::Cms::ChildList

    included do
      field :child_limit, type: Integer, default: 5
      field :child_loop_html, type: String
      field :child_upper_html, type: String
      field :child_lower_html, type: String
      permit_params :child_limit, :child_loop_html
      permit_params :child_upper_html, :child_lower_html
      before_validation :set_child_limit
    end

    def set_child_limit
      self.child_limit = 0 if child_limit.blank? || child_limit.negative?
    end
  end
end
