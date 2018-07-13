class Gws::Questionnaire::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Questionnaire::File

  before_action :set_forms
  before_action :set_cur_form
  before_action :check_form_permissions
  before_action :set_items
  before_action :set_item, only: %i[edit update delete destroy]

  navi_view "gws/questionnaire/main/navi"

  private

  def set_crumbs
    set_cur_form
    @crumbs << [t('modules.gws/questionnaire'), gws_questionnaire_main_path]
    @crumbs << [t('ss.navi.readable'), gws_questionnaire_readables_path]
    @crumbs << [@cur_form.name, action: :edit]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Questionnaire::Form.site(@cur_site)
      if params[:state] != 'preview'
        criteria = criteria.and_public
      end
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
    { name: t("gws/questionnaire.file_name", form: @cur_form.name) }
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

  def edit
    render_opts = {}
    render_opts[:layout] = false if request.xhr?
    render render_opts
  end

  def update
    custom = params.require(:custom)
    new_column_values = @cur_form.build_column_values(custom)
    @item.update_column_values(new_column_values)
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_opts = { location: { action: :edit } }

    result = @item.save
    if result
      @cur_form.set_answered!(@cur_user)
    end

    render_update result, render_opts
  end

  def delete
    render
  end

  def destroy
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
end
