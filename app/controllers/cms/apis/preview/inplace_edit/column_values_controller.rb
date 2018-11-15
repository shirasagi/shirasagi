class Cms::Apis::Preview::InplaceEdit::ColumnValuesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Column::Value::Base

  layout "ss/ajax_in_iframe"

  before_action :set_inplace_mode
  before_action :set_item
  before_action :set_column, only: %i[new]
  before_action :set_column_and_value, only: %i[edit update destroy move_up move_down move_at]

  private

  def set_inplace_mode
    @inplace_mode = true
  end

  def set_item
    @item = @cur_page = Cms::Page.site(@cur_site).find(params[:page_id]).becomes_with_route
    raise "404" if !@item.respond_to?(:form) || !@item.respond_to?(:column_values)

    @model = @item.class
  end

  def set_column
    @cur_column = @item.form.columns.find(params[:column_id].to_s)
  end

  def set_column_and_value
    @cur_column_value = @item.column_values.find(params[:id])

    @cur_column = @cur_column_value.column
    raise "404" if @cur_column.blank?
  end

  public

  def new
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.state == "public"
      raise "403" if !@item.allowed?(:release, @cur_user, site: @cur_site)
    end

    @preview = true
    render action: :new
  end

  def create
    @item.attributes = fix_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.state == "public"
      raise "403" if !@item.allowed?(:release, @cur_user, site: @cur_site)
    end

    @preview = true

    safe_params = params.require(:item).permit(@model.permit_params)
    column_value_param = safe_params[:column_values].first
    column_value_param[:order] = @item.column_values.present? ? @item.column_values.max(:order) + 1 : 0
    @cur_column_value = @item.column_values.build(column_value_param)
    @cur_column = @cur_column_value.column

    if params.key?(:save_if_no_alerts)
      result = @item.valid?(%i[update accessibility link])
      if result
        result = @item.save
      end
    else
      result = @item.save
    end

    location = { action: :edit, id: @cur_column_value }
    if result
      flash["ss.inplace_edit.notice"] = t("ss.notice.saved")
      if @item.try(:branch?) && @item.state == "public"
        location = { action: :index }
        @item.delete
      end
    end
    render_create result, location: location, render: { file: :new, status: :unprocessable_entity }
  end

  def edit
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.state == "public"
      raise "403" if !@item.allowed?(:release, @cur_user, site: @cur_site)
    end

    @preview = true
    render action: :edit
  end

  def update
    safe_params = params.require(:item).permit(@model.permit_params)
    column_value_param = safe_params[:column_values].first
    @cur_column_value.attributes = column_value_param[:in_wrap]
    @item.attributes = fix_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.state == "public"
      raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site, node: @cur_node)
      @item.state = "ready" if @item.try(:release_date).present?
    end

    if params.key?(:save_if_no_alerts)
      result = @item.valid?(%i[update accessibility link])
      if result
        result = @item.save
      end
    else
      result = @item.save
    end

    location = { action: :edit }
    if result
      flash["ss.inplace_edit.notice"] = t("ss.notice.saved")
      if @item.try(:branch?) && @item.state == "public"
        # location = { action: :index }
        @item.delete
      end
    end
    render_update result, location: location, render: { file: :edit, status: :unprocessable_entity }
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)

    result = @cur_column_value.destroy
    if result
      respond_to do |format|
        format.html { head :no_content }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render file: :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def move_up
    copy = Array(@item.column_values.order_by(order: 1, name: 1).to_a)
    index = copy.index { |value| value.id == @cur_column_value.id }
    if index && index > 0
      copy[index - 1], copy[index] = copy[index], copy[index - 1]
    end
    copy.each_with_index { |value, index| value.order = index }

    @item.column_values = copy
    result = @item.save

    if result
      render json: Hash[copy.map { |value| [ value.id, value.order ] }], status: :ok, content_type: json_content_type
    else
      respond_to do |format|
        format.html { render file: :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def move_down
    copy = Array(@item.column_values.order_by(order: 1, name: 1).to_a)
    index = copy.index { |value| value.id == @cur_column_value.id }
    if index && index < copy.length - 1
      copy[index], copy[index + 1] = copy[index + 1], copy[index]
    end
    copy.each_with_index { |value, index| value.order = index }

    @item.column_values = copy
    result = @item.save

    if result
      render json: Hash[copy.map { |value| [ value.id, value.order ] }], status: :ok, content_type: json_content_type
    else
      respond_to do |format|
        format.html { render file: :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def move_at
    order = Integer(params[:order])

    copy = Array(@item.column_values.order_by(order: 1, name: 1).to_a)
    index = copy.index { |value| value.id == @cur_column_value.id }

    if index && index != order
      delete_index = index

      insert_index = order
      insert_index = -1 if insert_index < 0
      insert_index = -1 if insert_index >= copy.length
      insert_index -= 1 if delete_index < insert_index

      copy.insert(insert_index, copy.delete_at(delete_index))
    end

    copy.each_with_index { |value, index| value.order = index }

    @item.column_values = copy
    result = @item.save

    if result
      render json: Hash[copy.map { |value| [ value.id, value.order ] }], status: :ok, content_type: json_content_type
    else
      respond_to do |format|
        format.html { render file: :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end
end
