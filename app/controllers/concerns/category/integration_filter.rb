module Category::IntegrationFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_item
    before_action :set_model
  end

  private
    def set_item
      @item = @cur_node.becomes_with_route
    end

    def set_model
      @model = @item.class
    end

  public
    def split
      #raise "403" unless @item.allowed?(:edit, @cur_user)

      return if request.get?
      @item.attributes = get_params
      #@item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      render_create @item.split, location: { action: :index }, render: { file: :split }
    end

    def integrate
      #raise "403" unless @item.allowed?(:edit, @cur_user)

      return if request.get?
      @item.attributes = get_params
      #@item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      render_create @item.integrate, location: { action: :index }, render: { file: :integrate }
    end
end
