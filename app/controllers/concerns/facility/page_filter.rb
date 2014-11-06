module Facility::PageFilter
  extend ActiveSupport::Concern
  include Cms::BaseFilter
  include Cms::PageFilter

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
          search(params[:s]).
          order_by(updated: -1).
          page(params[:page]).per(50)
      end
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
      if @item.state == "public"
        raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
        @item.state = "ready" if @item.release_date
      end
      render_create @item.save
    end

    def edit
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def update
      @item.attributes = get_params
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      if @item.state == "public"
        raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
        @item.state = "ready" if @item.release_date
      end
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
end
