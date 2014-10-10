module Cms::PageFilter::ViewCell
  extend ActiveSupport::Concern
  include SS::CellFilter

  included do
    helper ApplicationHelper
    before_action :inherit_variables
  end

  public
    def index
      render
    end
end
