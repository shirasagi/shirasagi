module Member::Photo::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  private
    def render_items(cond)
      if @cur_node
        raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
        @items = @model.site(@cur_site).node(@cur_node).
          allow(:read, @cur_user).
          search(params[:s]).
          where(cond).
          order_by(updated: -1).
          page(params[:page]).per(50)
      end
      @items = [] if !@items
      render file: :index
    end

  public
    def index_listable
      cond = { listable_state: "public" }
      render_items(cond)
    end

    def index_slideable
      cond = { slideable_state: "public" }
      render_items(cond)
    end
end
