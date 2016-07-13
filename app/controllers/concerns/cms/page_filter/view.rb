module Cms::PageFilter::View
  extend ActiveSupport::Concern
  include SS::AgentFilter

  included do
    helper Gravatar::GravatarHelper
    helper Map::MapHelper
  end

  def index
    render
  end
end
