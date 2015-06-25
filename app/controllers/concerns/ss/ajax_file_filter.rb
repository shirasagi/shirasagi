module SS::AjaxFileFilter
  extend ActiveSupport::Concern

  included do
    layout "ss/ajax"
  end

  private
    def append_view_paths
      append_view_path "app/views/ss/crud/ajax_files"
      super
    end
end
