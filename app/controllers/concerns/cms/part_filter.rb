module Cms::PartFilter
  extend ActiveSupport::Concern
  include Cms::NodeFilter

  private
    def redirect_url
      nil
    end
end
