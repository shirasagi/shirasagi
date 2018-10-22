class Gws::Survey::EditableFilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Survey::File

  before_action :set_forms
  before_action :set_cur_form
  before_action :set_search_params

  navi_view "gws/survey/main/navi"

  append_view_path "app/views/gws/survey/files"

  private

  def set_crumbs
    set_cur_form
    @crumbs << [@cur_site.menu_survey_label || t('modules.gws/survey'), gws_survey_main_path]
    @crumbs << [t('ss.navi.editable'), gws_survey_editables_path]
    @crumbs << [@cur_form.name, gws_survey_editable_path(id: @cur_form)]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Survey::Form.site(@cur_site)
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

    job_class = Gws::Survey::NotificationJob.bind(site_id: @cur_site)
    job_class.perform_later(@cur_form.id.to_s, { resend: true, unanswered_only: true, cur_user_id: @cur_user.id })
    redirect_to({ action: :index }, { notice: I18n.t('gws/survey.notices.notification_job_started') })
  end

  def download_all
    @items = @cur_form.files.search(@s).order_by(updated: -1)

    if request.get?
      render
      return
    end

    safe_params = params.require(:item).permit(:encoding)
    encoding = safe_params[:encoding]
    filename = "survey_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum(
      @items.enum_csv(OpenStruct.new(cur_site: @cur_site, cur_form: @cur_form, encoding: encoding)),
      type: "text/csv; charset=#{encoding}", filename: filename
    )
  end

  def zip_all_files
    file_ids = []
    @cur_form.files.search(@s).each do |file|
      file.column_values.each do |value|
        next if !value.is_a?(Gws::Column::Value::FileUpload)
        next if value.file_ids.blank?

        file_ids += value.file_ids
      end
    end

    if file_ids.blank?
      redirect_to({ action: :index }, { notice: t("gws/survey.notices.no_files") })
      return
    end

    zip_filename = "survey_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip"
    zip = Gws::Compressor.new(@cur_user, model: SS::File, items: SS::File.in(id: file_ids), filename: zip_filename)
    zip.url = sns_download_job_files_url(user: zip.user, filename: zip.filename)

    if zip.deley_download?
      job = Gws::CompressJob.bind(site_id: @cur_site, user_id: @cur_user)
      job.perform_later(zip.serialize)

      flash[:notice_options] = { timeout: 0 }
      redirect_to({ action: :index }, { notice: zip.delay_message })
    else
      raise '500' unless zip.save
      send_file(zip.path, type: zip.type, filename: zip.name, disposition: 'attachment', x_sendfile: true)
    end
  end
end
