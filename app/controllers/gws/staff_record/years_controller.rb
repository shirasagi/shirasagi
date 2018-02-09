class Gws::StaffRecord::YearsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::SettingFilter

  model Gws::StaffRecord::Year

  navi_view "gws/main/navi"

  before_action :set_year, if: ->{ @item && !@item.new_record? }

  private

  def set_crumbs
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

  def copy_situation
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if request.get?
      render
      return
    end

    job = Gws::StaffRecord::CopySituationJob.bind(site_id: @cur_site, user_id: @cur_user)
    job.perform_later(@item.id.to_s)

    redirect_to({ action: :show }, { notice: I18n.t('gws/staff_record.notice.copy_situation_started') })
  end
end
