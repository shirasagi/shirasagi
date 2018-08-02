class Cms::Node::ConfsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter
  include Cms::TrashFilter

  model Cms::Node

  navi_view "cms/node/main/navi"

  private

  def set_item
    @item = @cur_node
    @item.attributes = fix_params
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node.parent }
  end

  def redirect_url
    { action: :show }
  end

  def redirect_url_on_destroy
    @item.parent ? view_context.contents_path(@item.parent) : cms_nodes_path
  end

  public

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render_destroy @item.destroy, location: redirect_url_on_destroy
  end

  def soft_delete
    set_item unless @item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.deleted = Time.zone.now
    render_destroy @item.save, location: redirect_url_on_destroy
  end

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.deleted = nil

    render_opts = {}
    render_opts[:location] = redirect_url_on_destroy
    render_opts[:render] = { file: :undo_delete }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.save, render_opts
  end
end
