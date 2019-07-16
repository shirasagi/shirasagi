module Category::IntegrationFilter
  extend ActiveSupport::Concern

  def split
    @item = @cur_node.becomes_with_route
    @model = @item.class
    #raise "403" unless @item.allowed?(:edit, @cur_user)

    return if request.get?
    @item.attributes = get_params
    render_create @item.category_split, location: { action: :index }, render: { file: :split }
  end

  def integrate
    @item = @cur_node.becomes_with_route
    @model = @item.class
    #raise "403" unless @item.allowed?(:edit, @cur_user)

    return if request.get?
    @item.attributes = get_params
    render_create @item.category_integrate, location: { action: :index }, render: { file: :integrate }
  end
end
