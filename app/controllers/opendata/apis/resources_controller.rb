class Opendata::Apis::ResourcesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model Opendata::Resource

  before_action :set_dataset
  before_action :set_item

  private

  def dataset
    @dataset ||= Opendata::Dataset.site(@cur_site).node(@cur_node).find params[:dataset_id]
  end

  def set_dataset
    raise "403" unless dataset.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    @crumbs << [@dataset.name, opendata_dataset_path(id: @dataset)]
  end

  def set_item
    @item = dataset.resources.find params[:id]
  end

  def pre_params
    default_license = Opendata::License.site(@cur_site).and_public.and_default.order_by(order: 1, id: 1).first
    if default_license.present?
      { license_id: default_license.id }
    else
      {}
    end
  end

  def render_update(result, opts = {})
    if result
      flash[:notice] = opts[:notice] if opts[:notice]
      render json: items_json, status: :ok, content_type: json_content_type
    else
      render json: @item.errors.full_messages.join("\n"), status: :unprocessable_entity, content_type: json_content_type
    end
  end

  def items_json
    {}.to_json
  end

  public

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    render
  end

  def update
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    @item.attributes = get_params
    @item.workflow = { workflow_reset: true } if @dataset.member.present?
    result = @item.save

    render_update result
  end
end
