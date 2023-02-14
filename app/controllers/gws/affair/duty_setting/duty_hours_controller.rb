class Gws::Affair::DutySetting::DutyHoursController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  helper Gws::Schedule::PlanHelper

  model Gws::Affair::DutyHour

  navi_view "gws/affair/main/navi"

  before_action :check_deletable_item, only: %i[delete destroy]

  def destroy_all
    @selected_items.destroy_all if @selected_items.present?
    render_destroy_all true
  end

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).to_a

    if Gws::Affair::DefaultDutyHour.allowed?(:read, @cur_user, site: @cur_site)
      @items.unshift(Gws::Affair::DefaultDutyHour.new(cur_site: @cur_site))
    end
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path ]
    @crumbs << [ t("modules.gws/affair/duty_hour"), action: :index ]
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

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @selected_items = @items = @model.site(@cur_site).in(id: ids)
  end

  def check_deletable_item
    raise "404" if @item.is_a?(Gws::Affair::DefaultDutyHour)
  end
end
