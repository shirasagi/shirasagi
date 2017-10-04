class Gws::Workflow::ColumnsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::Column
  navi_view 'gws/workflow/settings/navi'

  before_action :set_form

  private

  def set_form
    @cur_form ||= Gws::Workflow::Form.site(@cur_site).find(params[:form_id])
  end

  def set_crumbs
    set_form
    @crumbs << [t('modules.gws/workflow'), gws_workflow_setting_path]
    @crumbs << [Gws::Workflow::Form.model_name.human, gws_workflow_forms_path]
    @crumbs << [@cur_form.name, gws_workflow_form_path(id: @cur_form)]
  end

  def fix_params
    set_form
    { cur_user: @cur_user, cur_site: @cur_site, cur_form: @cur_form }
  end

  def set_item
    set_form
    @item = @cur_form.columns.find(params[:id])
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_selected_items
    set_form
    ids = params[:ids]
    raise '400' unless ids
    ids = ids.split(",") if ids.kind_of?(String)
    @items = @cur_form.columns.in(id: ids)
    raise '400' unless @items.present?
  end

  public

  def index
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site)

    @items = @cur_form.columns.
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def new
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def update
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end

  def delete
    raise '403' unless @cur_form.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' unless @cur_form.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    raise '403' unless @cur_form.allowed?(:delete, @cur_user, site: @cur_site)

    entries = @items.entries
    @items = []

    entries.each do |item|
      next if item.destroy
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
