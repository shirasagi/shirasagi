class Member::MyAnpiPostsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Board::AnpiPost

  navi_view "cms/node/main/navi"

  private
    def fix_params
      @cur_node = @cur_node.becomes_with_route
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def redirect_url
      { action: :show, id: @item.id }
    end

  public
    def index
      @items = @model.site(@cur_site).search(params[:s]).
        allow(:read, @cur_user, site: @cur_site).
        order(descendants_updated: -1).
        page(params[:page]).per(50)
    end

    def download
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      csv = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site).order(updated: -1).to_csv
      send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "anpi_posts_#{Time.zone.now.to_i}.csv"
    end

    # Google Person Finder
    def edit_gpf
      set_item
    end

    # Google Person Finder
    def update_gpf
      set_item

      @item.upload_to_gpf
      redirect_to({ action: :show }, { notice: I18n.t("member.notice.posted_gpf") })
    end
end
