class Inquiry::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::ColumnFilter2

  model Inquiry::Column
  self.form_model = Inquiry::Node::Form

  navi_view "inquiry/main/navi"
  append_view_path 'app/views/inquiry/columns2'

  before_action :set_inquiry_assets
  before_action :check_permission

  private

  def set_inquiry_assets
    javascript "/assets/js/ckeditor/ckeditor.js"
    javascript "/assets/js/ckeditor/adapters/jquery.js"
  end

  def fix_params
    { cur_site: @cur_site, node_id: @cur_node.id }
  end

  def check_permission
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
  end

  def cur_form
    @cur_form ||= @cur_node
  end

  def column_route_options
    Inquiry::Column.route_options
  end

  def set_model
    model = self.class.model_class
    @model = model
  end

  def set_default_attributes
    if params[:type]
      @item.input_type = params[:type].sub(/.*\//, '')
      @item.name = I18n.t("inquiry.columns.#{params[:type]}", default: params[:type])
    end

    case params[:type]
    when 'inquiry/radio_button'
      @item.select_options = I18n.t("gws/column.default_select_options").to_a
    when 'inquiry/select'
      @item.select_options = I18n.t("gws/column.default_select_options").to_a
    when 'inquiry/check_box'
      @item.select_options = I18n.t("gws/column.default_select_options").to_a
    when 'inquiry/form_select'
      @item.select_options = I18n.t("gws/column.default_select_options").to_a
    end
  end

  public

  def create
    set_model
    raise '403' unless cur_form.allowed?(:edit, @cur_user, site: @cur_site)

    @item = Inquiry::Column.new(cur_site: @cur_site, site: @cur_site, node: @cur_node)
    set_default_attributes

    @item.order = placement == "bottom" ? cur_form.columns.max(:order).to_i + 10 : 10
    @item.required = cur_form.columns.reorder(order: -1).only(:required).first.try(:required) || "required"
    unless @item.save
      json = { status: 422, errors: @item.errors.full_messages }
      render json: json, status: :unprocessable_entity, content_type: json_content_type
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
    locals = { ref: SS.request_path(request), model: @model, item: @item, new_item: true }
    render template: "inquiry/frames/columns/edit", locals: locals, layout: "ss/item_frame"
  end
end
