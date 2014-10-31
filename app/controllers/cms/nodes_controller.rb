class Cms::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Cms::Node

  navi_view "cms/main/navi"

  private
    def set_crumbs
      #@crumbs << [:"cms.node", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

    def pre_params
      { route: "cms/node" }
    end

    def redirect_url
      nil
    end

  public
    def index
      @items = @model.site(@cur_site).
        allow(:read, @cur_user).
        where(depth: 1).
        order_by(filename: 1).
        page(params[:page]).per(50)
    end

    def routes
      @items = {}

      Cms::Node.new.route_options.each do |name, path|
        mod = path.sub(/\/.*/, '')
        @items[mod] = { name: t("modules.#{mod}"), items: [] } if !@items[mod]
        @items[mod][:items] << [ name.sub(/.*\//, ""), path ]
      end

      render layout: "ss/ajax"
    end
end
