class Gws::Survey::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Survey::File

  before_action :set_forms
  before_action :set_cur_form
  before_action :check_form_permissions
  before_action :set_items
  before_action :set_item, only: %i[show edit update delete destroy others print]

  navi_view "gws/survey/main/navi"

  private

  def set_crumbs
    set_cur_form
    @crumbs << [@cur_site.menu_survey_label || t('modules.gws/survey'), gws_survey_main_path]
    @crumbs << [t('ss.navi.readable'), gws_survey_readables_path]
    @crumbs << [@cur_form.name, action: :edit]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Survey::Form.site(@cur_site).without_deleted
      criteria = criteria.and_public
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    raise '404' if params[:readable_id].blank?
    @cur_form ||= begin
      set_forms
      @forms.find(params[:readable_id])
    end
  end

  def check_form_permissions
    raise '403' unless @cur_form.readable?(@cur_user, site: @cur_site)
  end

  def fix_params
    set_cur_form
    { cur_site: @cur_site, cur_user: @cur_user, cur_form: @cur_form }
  end

  def pre_params
    { name: t("gws/survey.file_name", form: @cur_form.name), anonymous_state: @cur_form.anonymous_state }
  end

  def set_items
    @items ||= begin
      items = @model.site(@cur_site).form(@cur_form)
      if @cur_form.file_closed?
        items = items.user(@cur_user)
      end
      items
    end
  end

  def set_item
    @item ||= begin
      item = @items.where(user_id: @cur_user.id).order_by(created: 1).first
      item ||= @model.new(pre_params)
      item.attributes = fix_params
      item
    end
  end

  public

  def show
    render
  end

  def edit
    if @item.persisted? && !@cur_form.file_editable?
      redirect_to(action: :show)
      return
    end

    render_opts = {}
    render_opts[:layout] = false if request.xhr?
    render render_opts
  end

  def update
    raise '403' if @item.persisted? && !@cur_form.file_editable?

    custom = params.require(:custom) rescue {}
    new_column_values = @cur_form.build_column_values(custom)
    @item.update_column_values(new_column_values)
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_opts = {
      location: gws_survey_readables_path(s: { answered_state: "" }),
      notice: t("ss.notice.answered"),
    }

    result = @item.save
    if result
      @cur_form.set_answered!(@cur_user)
    end

    render_update result, render_opts
  end

  def delete
    raise '403' if !@cur_form.file_editable?
    render
  end

  def destroy
    raise '403' if !@cur_form.file_editable?

    render_opts = { location: { action: :edit } }
    if @item.new_record?
      render_destroy true, render_opts
      return
    end

    result = @item.destroy
    if result
      @cur_form.unset_answered!(@cur_user)
    end

    render_destroy result, render_opts
  end

  def others
    raise '404' if @cur_form.file_closed?
    @items = @items.ne(user_id: @cur_user.id).order_by(updated: -1).page(params[:page]).per(50)
  end

  def print
    render layout: 'ss/print'
  end
end
