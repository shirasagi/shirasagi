module Sns::BaseFilter
  extend ActiveSupport::Concern
  include SS::BaseFilter

  included do
    before_action :set_crumbs
    navi_view "sns/main/navi"
  end

  private
    def set_crumbs
      #
    end
end
