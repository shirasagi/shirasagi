class Cms::Form::InitColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::InitColumn

  navi_view "cms/main/conf_navi"

  before_action :set_form
  before_action :check_form_type
  before_action :set_items, only: %i[index]
  before_action :set_item, only: %i[show edit update delete destroy]

  private

  def set_form
    @cur_form ||= Cms::Form.site(@cur_site).find(params[:form_id])
  end

  def check_form_type
    raise "404" if @cur_form.blank? || !@cur_form.sub_type_entry?
  end

  def set_items
    @items = @cur_form.init_columns
  end

  def set_item
    set_form
    @item = @cur_form.init_columns.find(params[:id])
    @item.attributes = fix_params

    @model = @item.class
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_crumbs
    set_form
    @crumbs << [Cms::Form.model_name.human, cms_forms_path]
    @crumbs << [@cur_form.name, cms_form_path(id: @cur_form)]
    @crumbs << [Cms::InitColumn.model_name.human, action: :index]
  end

  def fix_params
    set_form
    { cur_site: @cur_site, cur_form: @cur_form }
  end

  def pre_params
    ret = super || {}

    max_order = @cur_form.init_columns.max(:order) || 0
    ret[:order] = max_order + 10
    ret
  end

  def set_column
    column_id = params[:column_id].presence || params.dig(:item, :column_id) || @item.column.id
    @column = @cur_form.columns.find(column_id)
  end

  public

  def index
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site)

    @items = @items.order_by(order: 1).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    set_column
    render
  end

  def new
    set_column
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new
  end

  def create
    set_column
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    set_column
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_update @item.update
  end

  def delete
    raise '403' unless @cur_form.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
    render
  end

  def destroy
    raise '403' unless @cur_form.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
    render_destroy @item.destroy
  end

  def destroy_all
    raise '403' unless @cur_form.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)

    entries = @items.entries
    @items = []

    entries.each do |item|
      next if item.destroy
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
