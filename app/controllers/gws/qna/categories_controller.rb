class Gws::Qna::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/qna/settings/navi"

  model Gws::Qna::Category

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
    @crumbs << [t("mongoid.models.gws/qna/group_setting"), gws_qna_setting_path]
    @crumbs << [t("mongoid.models.gws/qna/group_setting/category"), gws_qna_topics_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
