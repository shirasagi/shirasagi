class Gws::StaffRecord::YearsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::StaffRecord::Year

  navi_view "gws/staff_record/settings/navi"

  before_action :set_year, if: ->{ @item && !@item.new_record? }

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/staff_record/group_setting"), gws_staff_record_setting_path]
    @crumbs << [t("mongoid.models.gws/staff_record/year"), gws_staff_record_years_path]
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
