module Sns::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter
  include Sys::LinkFilter

  included do
    before_action :set_crumbs
    navi_view "sns/main/navi"
  end

  private

  def set_crumbs
  end
end
