module Multilingual::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :lock, :unlock, :move, :copy]
  end

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
        @item.state = "ready" if @item.try(:release_date).present?
      end
      render_create @item.save
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @item.allowed?(:edit, @cur_user)
      if @item.state == "public"
        @item.state = "ready" if @item.try(:release_date).present?
      end

      result = @item.update
      location = nil
      if result && @item.try(:branch?) && @item.state == "public"
        location = { action: :index }
        @item.delete
      end
      render_update result, location: location
    end
end
