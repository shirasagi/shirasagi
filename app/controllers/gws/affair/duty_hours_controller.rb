class Gws::Affair::DutyHoursController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  helper Gws::Schedule::PlanHelper

  model Gws::Affair::DutyHour

  navi_view "gws/affair/main/navi"

  before_action :check_deletable_item, only: %i[delete destroy]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/duty_hour"), action: :index ]
  end

  def permit_fields
    ret = super
    if @item && @item.is_a?(Gws::Affair::DefaultDutyHour)
      ret.delete(:name)
    end
    ret
  end

  def set_item
    @item ||= begin
      if params[:id] == "default"
        Gws::Affair::DefaultDutyHour.new(cur_site: @cur_site)
      else
        item = @model.find(params[:id])
        item.attributes = fix_params
        item
      end
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def check_deletable_item
    raise "404" if @item.is_a?(Gws::Affair::DefaultDutyHour)
  end
end
