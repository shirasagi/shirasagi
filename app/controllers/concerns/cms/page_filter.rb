# coding: utf-8
module Cms::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  public
    def index
      if @cur_node
        raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

        @items = @model.site(@cur_site).node(@cur_node).
          allow(:read, @cur_user).
          search(params[:s]).
          order_by(updated: -1).
          page(params[:page]).per(50)
      end
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      if @item.state == "public"
        raise "403" unless @item.allowed?(:release, @cur_user)
        @item.state = "ready" if @item.release_date
      end
      render_create @item.save
    end

    def update
      @item.attributes = get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      if @item.state == "public"
        raise "403" unless @item.allowed?(:release, @cur_user)
        @item.state = "ready" if @item.release_date
      end
      render_update @item.update
    end
end
