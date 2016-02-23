module Cms::PageFilter::View
  extend ActiveSupport::Concern
  include SS::AgentFilter

  def index
    render
  end
end
