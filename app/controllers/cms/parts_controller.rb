class Cms::PartsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PartFilter

  model Cms::Part

  navi_view "cms/main/navi"
  menu_view "cms/main/node_menu"

  private
    def set_crumbs
      #@crumbs << [:"cms.part", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
    end

    def pre_params
      { route: "cms/free" }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        allow(:read, @cur_user).
        where(depth: 1).
        search(params[:s]).
        order_by(filename: 1).
        page(params[:page]).per(50)
    end

    def routes
      @items = {}

      Cms::Part.new.route_options.each do |name, path|
        mod = path.sub(/\/.*/, '')
        @items[mod] = { name: t("modules.#{mod}"), items: [] } if !@items[mod]
        @items[mod][:items] << [ name.sub(/.*\//, ""), path ]
      end

      render file: "cms/nodes/routes", layout: "ss/ajax"
    end
end
