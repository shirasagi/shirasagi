class Urgency::ErrorsController < ApplicationController
  include Cms::BaseFilter

  append_view_path "app/views/cms/layouts"
  navi_view "urgency/main/navi"

  public
    def show
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

      error_id = params[:id].to_i
      @errors = []
      if error_id == 1
        @errors << t("urgency.errors.default_layout_not_found")
      elsif error_id == 2
        @errors << t("urgency.errors.index_page_not_found")
      end
    end
end
