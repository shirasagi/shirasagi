module Cms::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  private
    def pre_params
      if @cur_node
        layout_id = @cur_node.page_layout_id || @cur_node.layout_id
        { layout_id: layout_id }
      else
        {}
      end
    end

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
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @item.allowed?(:edit, @cur_user)
      if @item.state == "public"
        raise "403" unless @item.allowed?(:release, @cur_user)
        @item.state = "ready" if @item.release_date
      end
      render_update @item.update
    end
end
