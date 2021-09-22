module Category::IntegrationFilter
  extend ActiveSupport::Concern

  def split
    set_item
    @item = @item.becomes_with_route
    @model = @item.class
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get?
    @item.attributes = get_params
    render_create @item.category_split, location: redirect_url, render: { template: "split" }
  end

  def integrate
    set_item
    @item = @item.becomes_with_route
    @model = @item.class
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get?
    @item.attributes = get_params
    render_create @item.category_integrate, location: redirect_url, render: { template: "integrate" }
  end
end
