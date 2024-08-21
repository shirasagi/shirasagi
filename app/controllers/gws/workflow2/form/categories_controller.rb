class Gws::Workflow2::Form::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow2::Form::Category

  navi_view "gws/workflow2/main/navi"

  def index
    #raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @search_params = params[:s]
    @search_params = @search_params.delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
    if @search_params
      @items = @items.search(@search_params).page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow2_label || t("modules.gws/workflow2"), gws_workflow2_files_main_path]
    @crumbs << [t("gws/workflow2.navi.form.category"), url_for(action: :index)]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
