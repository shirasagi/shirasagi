class Gws::Affair::CapitalYearsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::CapitalYear

  navi_view "gws/affair/main/navi"

  before_action :set_year, if: ->{ @item && !@item.new_record? }

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("mongoid.models.gws/affair/capital_year"), gws_affair_capital_years_path]
  end

  def set_year
    @cur_year = @item
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
