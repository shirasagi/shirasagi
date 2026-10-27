module Cms::PageFilter::View
  extend ActiveSupport::Concern
  include SS::AgentFilter

  included do
    helper Gravatar::GravatarHelper
    helper Map::MapHelper
  end

  def index
    if @cur_page.is_a?(Cms::Addon::RedirectLink) && @cur_page.effective_redirect_link.present?
      request.env["ss.redirect_path"] = @cur_page.effective_redirect_link
      redirect_to @cur_page.effective_redirect_link
      return
    end
    render
  end
end
