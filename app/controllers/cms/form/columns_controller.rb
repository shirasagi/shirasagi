class Cms::Form::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Column::Base

  navi_view "cms/form/main/navi"

  helper_method :column_type_options, :form_is_in_use?

  private

  def set_form
    @cur_form ||= Cms::Form.site(@cur_site).find(params[:form_id])
  end

  def set_items
    set_form
    @items = @cur_form.columns
  end

  def set_item
    set_form
    @item = @cur_form.columns.find(params[:id])
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
    @crumbs << [Cms::Column::Base.model_name.human, action: :index]
  end

  def fix_params
    set_form
    { cur_site: @cur_site, cur_form: @cur_form }
  end

  def pre_params
    ret = super || {}

    max_order = @cur_form.columns.max(:order) || 0
    ret[:order] = max_order + 10

    if @cur_form.sub_type_entry?
      ret[:required] = "optional"
    end
    ret
  end

  def column_type_options
    items = {}

    Cms::Column.route_options.each do |name, path|
      mod = path.sub(/\/.*/, '')
      items[mod] = { name: t("modules.#{mod}"), items: [] } if !items[mod]
      items[mod][:items] << [ name.sub(/.*\//, ''), path ]
    end

    items
  end

  def form_is_in_use?
    return @form_is_in_use if !@form_is_in_use.nil?

    set_form
    @form_is_in_use = Cms::Page.site(@cur_site).where(form_id: @cur_form.id).present?
  end

  def set_column_model
    raise "404" if params[:type].blank?

    type = params[:type].sub('/', '/column/').classify
    models = Cms::Column.route_options.collect do |k, v|
      v.sub('/', '/column/').classify.constantize
    end
    model = models.find { |m| m.to_s == type }
    raise '404' unless model

    @model = model
  end

  public

  def index
    set_items
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site)

    @items = @items.search(params[:s]).
      order_by(order: 1).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless @cur_form.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    render
  end

  def new
    set_column_model
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    set_column_model
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    raise '403' unless @cur_form.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
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
    if form_is_in_use? && params[:in_delete_confirmation].to_s != "yes"
      @item.errors.add :base, :unable_to_delete_in_use_column_without_confirmation
      render_destroy false
      return
    end

    render_destroy @item.destroy
  end

  def destroy_all
    if form_is_in_use?
      redirect_to url_for(action: :index), notice: t("errors.messages.unable_to_delete_all_columns_if_form_is_in_use")
      return
    end
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
