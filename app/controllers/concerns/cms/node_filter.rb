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

      cell = "#{@item.route.sub('/', '/nodes/')}/edit"
      resp = render_cell cell, params[:action]

      if resp.is_a?(String)
        @resp = resp
      else
        @item = resp
      end
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
      render_route
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      render_route
    end

    def create
      @item = @model.new get_params
      render_route
      render_create @resp.blank?, location: redirect_url
    end

    def edit
      render_route
    end

    def update
      @item.attributes = get_params
      render_route
      render_update @resp.blank?, location: redirect_url
    end

    def delete
      render_route
    end

    def destroy
      render_route
      render_destroy @resp.blank?, location: redirect_url
    end
end
