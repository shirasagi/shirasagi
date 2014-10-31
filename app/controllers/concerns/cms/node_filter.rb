module Cms::NodeFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  private
    def append_view_paths
      append_view_path ["app/views/cms/nodes", "app/views/ss/crud"]
    end

    def render_route
      @item.route = params[:route] if params[:route].present?
      @fix_params = fix_params

      controller = "#{@item.route.sub('/', '/agents/nodes/')}/edit"
      resp = render_agent controller, params[:action]

      @resp = resp.body.html_safe

      resp.code != "200"
    end

    def redirect_url
      diff = @item.route.pluralize != params[:controller]
      diff ? node_node_path(cid: @cur_node, id: @item.id) : { action: :show, id: @item.id }
    end

  public
    def show
      raise "403" unless @item.allowed?(:read, @cur_user)
      render_route
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      raise "403" unless @item.allowed?(:edit, @cur_user)
      render_route
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      render_create render_route, location: redirect_url
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user)
      render_route
    end

    def update
      raise "403" unless @item.allowed?(:edit, @cur_user)
      @item.attributes = get_params
      render_update render_route, location: redirect_url
    end

    def delete
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render_route
    end

    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render_destroy render_route
    end
end
