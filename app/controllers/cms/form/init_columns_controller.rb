class Cms::Form::InitColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::ColumnFilter2

  model Cms::InitColumn
  self.form_model = Cms::Form

  navi_view "cms/form/main/navi"
  append_view_path 'app/views/cms/init_columns'

  private

  def items
    @items ||= cur_form.init_columns.reorder(order: 1)
  end

  def set_model
    @model = self.class.model_class
  end

  public

  def create
    raise '403' unless cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    column_id = params[:type]
    column = cur_form.columns.where(id: column_id).first_or_initialize

    @item = @model.new(cur_site: @cur_site, site: @cur_site, form: cur_form)
    @item.column_id = column.id
    @item.column_type = column._type
    @item.order = placement == "bottom" ? cur_form.init_columns.max(:order).to_i + 10 : 10
    unless @item.save
      json = { status: 422, errors: @item.errors.full_messages }
      render json: json, status: :unprocessable_content, content_type: json_content_type
      return
    end

    if placement == "top"
      next_order = 20
      cur_form.init_columns.ne(id: @item.id).only(:id, :order).reorder(order: 1).to_a.each do |column|
        column.set(order: next_order)
        next_order += 10
      end
    end

    @frame_id = "item-#{@item.id}"
    locals = { ref: SS.request_path(request), model: @model, item: @item, new_item: true }
    render template: "cms/frames/init_columns/show", locals: locals, layout: "ss/item_frame"
  end

  def reorder
    ids = params.require(:ids)
    id_order_map = ids.index_with.with_index do |id, index|
      (index + 1) * 10
    end

    cur_form.init_columns.only(:id, :order).each do |column|
      next unless id_order_map.key?(column.id.to_s)

      order = id_order_map[column.id.to_s]
      column.set(order: order)
    end

    json = { status: 200 }
    render json: json, status: :ok, content_type: json_content_type
  end
end
