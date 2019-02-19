class Cms::Node::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Cms::Page

  prepend_view_path "app/views/cms/pages"
  navi_view "cms/node/main/navi"

  before_action :set_tree_navi, only: [:index]

  private

  def pre_params
    params = super

    n = @cur_node.becomes_with_route
    if n.respond_to?(:st_forms) && n.st_form_ids.include?(n.st_form_default_id)
      default_form = n.st_form_default
    end

    if default_form.present?
      params[:form_id] = default_form.id
    end

    params
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @node_target_options = @model.new.node_target_options

    @items = @model.site(@cur_site).
      node(@cur_node, params.dig(:s, :target)).
      where(route: "cms/page").
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
