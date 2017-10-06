class Gws::Workflow::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::File

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]

  private

  def set_crumbs
    @crumbs << [t("modules.gws/workflow"), action: :index]
  end

  def set_forms
    @forms ||= Gws::Workflow::Form.site(@cur_site).readable(@cur_user, @cur_site).order_by(order: 1, id: 1)
  end

  def set_cur_form
    return if params[:form_id].blank?
    set_forms
    @cur_form ||= @forms.find(params[:form_id])
  end

  def set_item
    super
    @cur_form ||= @item.form if @item.present?
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site, state: 'closed' }
    params[:cur_form] = @cur_form if @cur_form
    params
  end

  public

  def index
    @items = @model.site(@cur_site).
      readable(@cur_user, @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless @item.readable?(@cur_user, site: @cur_site)
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
  end

  def create
    @item = @model.new get_params
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom).permit(@cur_form.columns.to_permitted_fields)
      new_custom_values = @model.build_custom_values(@cur_form, custom)
      @item.custom_values = @item.custom_values.to_h.deep_merge(new_custom_values)
    end
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_create @item.save
  end

  def edit
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom).permit(@cur_form.columns.to_permitted_fields)
      new_custom_values = @model.build_custom_values(@cur_form, custom)
      @item.custom_values = @item.custom_values.to_h.deep_merge(new_custom_values)
    end
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_update @item.save
  end

  def delete
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.destroyable?(@cur_user, site: @cur_site)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
