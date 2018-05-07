class Cms::CommandSettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Command

  navi_view "cms/main/conf_navi"

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :run]

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.cms/command'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def update
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params
    @item.output = nil
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end

  def run
    raise "403" unless @model.allowed?(:use, @cur_user, site: @cur_site, node: @cur_node)
    @target = 'site'
    @target_path = @cur_site.path
    render_update @item.run(@target, @target_path)
  end
end
