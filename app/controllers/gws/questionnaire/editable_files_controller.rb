class Gws::Questionnaire::EditableFilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Questionnaire::File

  before_action :set_forms
  before_action :set_cur_form
  before_action :set_search_params

  navi_view "gws/questionnaire/main/navi"

  append_view_path "app/views/gws/questionnaire/files"

  private

  def set_crumbs
    set_cur_form
    @crumbs << [t('modules.gws/questionnaire'), gws_questionnaire_main_path]
    @crumbs << [t('ss.navi.editable'), gws_questionnaire_editables_path]
    @crumbs << [@cur_form.name, gws_questionnaire_editable_path(id: @cur_form)]
    @crumbs << [t("gws/questionnaire.tabs.files"), action: :index]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Questionnaire::Form.site(@cur_site)
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    raise '404' if params[:editable_id].blank?
    @cur_form ||= begin
      set_forms
      @forms.find(params[:editable_id])
    end
  end

  def set_search_params
    @s = OpenStruct.new(params[:s].presence || {})
  end

  def fix_params
    set_cur_form
    { cur_site: @cur_site, cur_user: @cur_user, cur_form: @cur_form }
  end

  public

  def index
    @items = @cur_form.files.search(@s).order_by(updated: -1).page(params[:page]).per(50)
  end

  def summary
    @items = @cur_form.files
    @aggregation = @items.aggregate
  end

  def notification
    @items = @cur_form.files
    if request.get?
      render
      return
    end

    job_class = Gws::Questionnaire::NotificationJob.bind(site_id: @cur_site)
    job_class.perform_later(@cur_form.id.to_s, { resend: true, unanswered_only: true })
    redirect_to({ action: :index }, { notice: I18n.t('gws/questionnaire.notices.notification_job_started') })
  end

  def download_all
    @items = @cur_form.files.search(@s).order_by(updated: -1)

    if request.get?
      render
      return
    end

    safe_params = params.require(:item).permit(:encoding)
    encoding = safe_params[:encoding]
    filename = "questionnaire_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum(
      @items.enum_csv(OpenStruct.new(cur_site: @cur_site, cur_form: @cur_form, encoding: encoding)),
      type: "text/csv; charset=#{encoding}", filename: filename
    )
  end
end
