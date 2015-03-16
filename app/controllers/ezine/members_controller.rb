class Ezine::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Ezine::Member

  navi_view "ezine/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, node_id: @cur_node.id }
    end

  public
    def index
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        search(params[:s]).
        order_by(updated: -1).
        page(params[:page]).per(50)
    end

    def new
      @item = Ezine::Member.new(site_id: @cur_site.id, node_id: @cur_node.id)
    end

    def download
      # TODO: CSV export
    end
end
