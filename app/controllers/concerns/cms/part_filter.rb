module Cms::PartFilter
  extend ActiveSupport::Concern
  include Cms::NodeFilter

  private
    def append_view_paths
      append_view_path ["app/views/cms/parts", "app/views/ss/crud"]
    end

    def render_route
      @item.route = params[:route] if params[:route].present?
      @fix_params = fix_params

      controller = "#{@item.route.sub('/', '/agents/parts/')}/edit"
      resp = render_agent controller, params[:action]

      @resp = resp.body.html_safe

      resp.code != "200"
    end

    def redirect_url
      nil
    end
end
