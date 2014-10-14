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
      if params[:action] == "destroy"
        return cms_nodes_path unless @item.parent
        diff = @item.route.split("/")[0] != @item.parent.route.split("/")[0]
        return node_nodes_path(cid: @item.parent) if diff
        { controller: params[:controller], cid: @item.parent.id }
      else
        diff = @item.route.split("/")[0] != params[:controller].split("/")[0]
        diff ? { action: :show, id: @item } : nil
      end
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
      render_destroy render_route, location: redirect_url
    end
end
