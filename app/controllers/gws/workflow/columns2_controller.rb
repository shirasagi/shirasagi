class Gws::Workflow::Columns2Controller < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  cattr_accessor(:form_model)
  self.form_model = Gws::Workflow::Form

  helper_method :cur_form, :items, :column_type_options

  private

  def set_crumbs
    @crumbs << [ t('modules.gws/workflow'), gws_workflow_setting_path ]
    @crumbs << [ Gws::Workflow::Form.model_name.human, gws_workflow_forms_path ]
    @crumbs << [ cur_form.name, gws_workflow_form_path(id: cur_form) ]
  end

  def cur_form
    @cur_form ||= form_model.site(@cur_site).find(params[:form_id])
  end

  def items
    @items ||= cur_form.columns.reorder(order: 1)
  end

  def column_type_options
    @column_type_options ||= begin
      items = {}

      Gws::Column.route_options.each do |name, path|
        mod = path.sub(/\/.*/, '')
        items[mod] = { name: t("modules.#{mod}"), items: [] } if !items[mod]
        items[mod][:items] << [ name.sub(/.*\//, ''), path ]
      end

      items
    end
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
      render json: json, status: :unprocessable_entity, content_type: json_content_type
      return
    end

    if placement == "top"
      cur_form.columns.only(:id, :order).reorder(order: 1).each_with_index do |column, index|
        column.set(order: (index + 1) * 10)
      end
    end

    @frame_id = "item-#{@item.id}"
    render template: "gws/frames/columns/edit", locals: { ref: request.path, model: @model, item: @item }, layout: "ss/item_frame"
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
