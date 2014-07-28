# coding: utf-8
class Inquiry::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter

  model Inquiry::Column

  append_view_path "app/views/cms/pages"
  navi_view "inquiry/main/navi"

  public
    def index
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        order_by(order: 1).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      render
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    end

    def create
      @item = @model.new get_params
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render_create @item.save
    end

    def edit
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def update
      @item.attributes = get_params
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render_update @item.update
    end

    def delete
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def destroy
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render_destroy @item.destroy
    end

  private
    def fix_params
      { cur_site: @cur_site, node_id: @cur_node.id }
    end
end
