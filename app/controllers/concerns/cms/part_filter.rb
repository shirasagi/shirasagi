module Cms::PartFilter
  extend ActiveSupport::Concern
  include Cms::NodeFilter

  private
    def append_view_paths
      append_view_path ["app/views/cms/parts", "app/views/ss/crud"]
    end

    def redirect_url
      nil
    end
end
