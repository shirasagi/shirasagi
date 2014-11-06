class Facility::LocationsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Location

  prepend_view_path "app/views/cms/node/nodes"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/location" }
    end

  public
    def index
      @items = @model.site(@cur_site).node(@cur_node).
        allow(:read, @cur_user).
        order_by(filename: 1).
        page(params[:page]).per(50)
    end
end
