module Cms::RedirectPage
  extend ActiveSupport::Concern

  included do
    field :redirect_link, type: String
    permit_params :redirect_link
  end

  def view_layout
    redirect_link.present? ? "cms/redirect" : "cms/page"
  end
end
