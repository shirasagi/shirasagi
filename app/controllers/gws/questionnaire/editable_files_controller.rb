class Gws::Questionnaire::EditableFilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Questionnaire::File

  before_action :set_forms
  before_action :set_cur_form
  before_action :set_search_params
  # before_action :check_form_permissions
  # before_action :set_items
  # before_action :set_item, only: %i[edit update delete destroy]

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
      # if params[:state] != 'preview'
      #   criteria = criteria.and_public
      # end
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

  # def check_form_permissions
  #   raise '403' unless @cur_form.readable?(@cur_user, site: @cur_site)
  # end

  def fix_params
    set_cur_form
    { cur_site: @cur_site, cur_user: @cur_user, cur_form: @cur_form }
  end

  # def pre_params
  #   { name: t("gws/questionnaire.file_name", form: @cur_form.name) }
  # end

  # def set_items
  #   @items ||= begin
  #     items = @cur_form.files
  #   end
  # end

  # def set_item
  #   @item ||= begin
  #     item = @items.where(user_id: @cur_user.id).order_by(created: 1).first
  #     item ||= @model.new(pre_params)
  #     item.attributes = fix_params
  #     item
  #   end
  # end

  public

  def index
    @items = @cur_form.files.search(@s).order_by(updated: -1).page(params[:page]).per(50)
  end

  def summary
    @items = @cur_form.files
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
