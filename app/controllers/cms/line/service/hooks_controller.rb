class Cms::Line::Service::HooksController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/line/main/navi"

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :set_service_group

  private

  def set_crumbs
    @crumbs << [t("cms.line_service"), cms_line_service_groups_path]
    @crumbs << [t("cms.line_service_hook"), cms_line_service_group_hooks_path]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, group: @service_group }
  end

  def set_service_group
    @service_group = Cms::Line::Service::Group.site(@cur_site).find(params[:group_id])
  end

  def set_model
    @type = params[:type].presence
    @type = nil if @type == "-"
    @model = @type ? "#{Cms::Line::Service::Hook}::#{@type.classify}".constantize : Cms::Line::Service::Hook::Base
  end

  def set_item
    super
    @type = @item.type
    @model = @item.class
  end

  def set_items
    @items = @service_group.hooks
  end

  public

  def crop
    set_item
    return if request.get?

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_update @item.update, render: { template: "crop" }
  end
end
