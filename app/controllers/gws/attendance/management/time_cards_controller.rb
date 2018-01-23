class Gws::Attendance::Management::TimeCardsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Attendance::TimeCard

  private

  def set_crumbs
    @crumbs << [t('modules.gws/attendance'), gws_attendance_main_path]
    @crumbs << [t('ss.management'), gws_attendance_management_main_path]
  end

  public

  def index
    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
