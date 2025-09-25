module Gws::ColumnFilter2
  extend ActiveSupport::Concern
  include Gws::BaseFilter
  include Gws::CrudFilter

  included do
    cattr_accessor(:form_model)

    model Gws::Column::Base

    navi_view 'gws/main/conf_navi'
    menu_view 'gws/columns2/menu'
    append_view_path 'app/views/gws/columns2'

    helper_method :cur_form, :items, :column_type_options, :show_component
  end

  private

  def cur_form
    @cur_form ||= form_model.site(@cur_site).find(params[:form_id])
  end

  def items
    @items ||= cur_form.columns.reorder(order: 1)
  end

  def column_type_options
    @column_type_options ||= Gws::Column.column_type_options
  end

  def set_model
    model = self.class.model_class

    if params[:type].present?
      models = Gws::Column.route_options.collect do |k, v|
        v.sub('/', '/column/').classify.constantize
      end
      model = models.find { |m| m.to_s == params[:type].sub('/', '/column/').classify }
      raise '404' unless model
    end

    @model = model
  end

  def placement
    @placement ||= begin
      if params[:placement].to_s == "bottom"
        "bottom"
      else
        "top"
      end
    end
  end

  def show_component(item)
    Gws::Frames::Columns::ShowComponent.new(
      cur_site: @cur_site, cur_user: @cur_user, item: item, ref: request.path, column_type_options: column_type_options)
  end

  def edit_component(item)
    Gws::Frames::Columns::EditComponent.new(
      cur_site: @cur_site, cur_user: @cur_user, item: item, ref: request.path, new_item: true)
  end

  public

  def index
    raise '403' unless cur_form.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def create
    set_model
    raise '403' unless cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new(cur_site: @cur_site, site: @cur_site, form: cur_form)
    @item.attributes = @model.default_attributes
    @item.order = placement == "bottom" ? cur_form.columns.max(:order).to_i + 10 : 10
    @item.required = cur_form.columns.reorder(order: -1).only(:required).first.try(:required) || "required"
    unless @item.save
      json = { status: 422, errors: @item.errors.full_messages }
      render json: json, status: :unprocessable_content, content_type: json_content_type
      return
    end

    if placement == "top"
      next_order = 20
      cur_form.columns.ne(id: @item.id).only(:id, :order).reorder(order: 1).to_a.each do |column|
        column.set(order: next_order)
        next_order += 10
      end
    end

    @frame_id = "item-#{@item.id}"
    render edit_component(@item), layout: "ss/item_frame"
  end

  def reorder
    ids = params.require(:ids)
    id_order_map = ids.index_with.with_index do |id, index|
      (index + 1) * 10
    end

    cur_form.columns.only(:id, :order).each do |column|
      next unless id_order_map.key?(column.id.to_s)

      order = id_order_map[column.id.to_s]
      column.set(order: order)
    end

    json = { status: 200 }
    render json: json, status: :ok, content_type: json_content_type
  end
end
