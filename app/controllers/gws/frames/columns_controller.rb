class Gws::Frames::ColumnsController < ApplicationController
  include Gws::ApiFilter

  layout "ss/item_frame"
  model Gws::Column::Base

  before_action :set_frame_id
  helper_method :ref, :item

  alias item set_item

  private

  def set_frame_id
    @frame_id ||= "item-#{item.id}"
  end

  def ref
    @ref ||= begin
      ref = params[:ref].to_s.presence
      if ref && !Sys::TrustedUrlValidator.valid_url?(ref)
        ref = nil
      end

      ref.presence
    end
  end

  def model
    @item ? @item.class : Gws::Column::Base
  end

  def column_type_options
    @column_type_options ||= Gws::Column.column_type_options
  end

  def show_component
    Gws::Frames::Columns::ShowComponent.new(
      cur_site: @cur_site, cur_user: @cur_user, item: item, ref: ref, column_type_options: column_type_options)
  end

  def edit_component
    Gws::Frames::Columns::EditComponent.new(cur_site: @cur_site, cur_user: @cur_user, item: item, ref: ref)
  end

  def find_new_plugin(new_route)
    Gws::Column.find_plugin_by_path(new_route)
  end

  public

  def show
    raise "403" unless @item.form.allowed?(:read, @cur_user, site: @cur_site)
    render show_component
  end

  def edit
    raise "403" unless @item.form.allowed?(:edit, @cur_user, site: @cur_site)
    render edit_component
  end

  def update
    raise "403" unless @item.form.allowed?(:edit, @cur_user, site: @cur_site)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    unless @item.save
      render edit_component, status: :unprocessable_content
      return
    end

    flash[:notice] = t("ss.notice.saved")
    render show_component
  end

  def destroy
    raise "403" unless @item.form.allowed?(:delete, @cur_user, site: @cur_site)

    unless @item.destroy
      render show_component, status: :unprocessable_content
      return
    end

    json = { status: 200, notice: t("ss.notice.deleted") }
    render json: json, status: :ok, content_type: json_content_type
  end

  def change_type
    set_item
    new_route = params.require(:item).permit(:route)[:route].to_s
    new_plugin = find_new_plugin(new_route)
    raise "404" unless new_plugin
    raise "404" unless new_plugin.model_class

    # new_item = Mongoid::Factory.build(plugin.model_class, @item.attributes)
    new_item = new_plugin.model_class.instantiate_document(@item.attributes)
    result = new_item.save
    unless result
      render edit_component, status: :unprocessable_content
      return
    end

    @item = new_item
    @item.set(_type: @item.class.name)
    render edit_component
  end
end
