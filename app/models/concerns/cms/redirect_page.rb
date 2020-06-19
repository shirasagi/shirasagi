module Cms::RedirectPage
  extend ActiveSupport::Concern

  def redirect_link
    nil
  end

  def view_layout
    redirect_link.present? ? "cms/redirect" : "cms/page"
  end
end
