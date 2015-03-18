class Ezine::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Ezine::Member

  navi_view "ezine/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, node_id: @cur_node.id }
    end

    def export_csv
      require "csv"

      items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        order_by(updated: -1)

      csv = CSV.generate do |data|
        data << %w(email email_type created)
        items.each do |item|
          row = []
          row << item.email
          row << item.email_type
          row << item.created.strftime("%Y-%m-%d %H:%m")

          data << row
        end
      end
      send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
        filename: "ezine_members_#{Time.now.to_i}.csv"
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
      export_csv
    end
end
