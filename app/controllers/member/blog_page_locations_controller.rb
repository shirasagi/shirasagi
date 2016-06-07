class Member::BlogPageLocationsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Member::Node::BlogPageLocation

  private
    def redirect_url
      { action: :show, id: @item.id }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).node(@cur_node).
        allow(:read, @cur_user).
        search(params[:s]).
        order_by(released: -1).
        page(params[:page]).per(50)
    end

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

end
