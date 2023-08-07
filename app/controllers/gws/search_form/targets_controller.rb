class Gws::SearchForm::TargetsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::SearchForm::Target

  navi_view 'gws/search_form/main/conf_navi'

  private

  def set_crumbs
    @crumbs << [t("gws/search_form.main"), gws_search_form_targets_path]
    @crumbs << [t("mongoid.models.gws/search_form/target"), gws_search_form_targets_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      search(params[:s]).
      order(name_for_index: 1).
      page(params[:page]).per(50)
  end
end
