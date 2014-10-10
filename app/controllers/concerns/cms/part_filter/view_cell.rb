module Cms::PartFilter::ViewCell
  extend ActiveSupport::Concern
  include SS::CellFilter

  included do
    helper ApplicationHelper
    before_action :prepend_current_view_path
    before_action :inherit_variables
    before_action :set_item
  end

  private
    def prepend_current_view_path
      prepend_view_path "app/cells/#{controller_path}"
    end

    def set_item
      @cur_part = @cur_part.becomes_with_route
    end
end
