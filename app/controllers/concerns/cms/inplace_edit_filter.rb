module Cms::InplaceEditFilter
  extend ActiveSupport::Concern

  included do
    helper_method :creates_branch?
  end

  private

  def creates_branch?
    @item.state != "closed"
  end
end
