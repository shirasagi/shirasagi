class Gws::Share::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/share/settings/navi"

  model Gws::Share::Category

  def index
    #raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @search_params = params[:s]
    @search_params = @search_params.delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(@search_params).
      tree_sort
    @items = Kaminari.paginate_array(@items.to_a).page(params[:page]).per(50)
  end

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/share/group_setting", gws_share_files_path]
      @crumbs << [:"mongoid.models.gws/share/group_setting/category", gws_share_files_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
