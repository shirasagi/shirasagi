module Cms::PageFilter::View
  extend ActiveSupport::Concern
  include SS::AgentFilter

  public
    def index
      render
    end
end
