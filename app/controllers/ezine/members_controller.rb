class Ezine::MembersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Ezine::Member

  navi_view "ezine/main/navi"

  before_action :set_columns, except: :index

  helper "ezine/form"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, node_id: @cur_node.id }
    end

    def get_params
      fix_fields = permit_fields + [ in_data: @columns.map{ |c| c.id.to_s } ]
      params.require(:item).permit(fix_fields).merge(fix_params)
    rescue
      raise "400"
    end

    def set_columns
      @columns = Ezine::Column.site(@cur_site).node(@cur_node).
        where(state: "public").order_by(order: 1)
    end

    def export_csv
      require "csv"

      items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        order_by(updated: -1)

      csv = CSV.generate do |data|
        data << %w(email email_type created) + @columns.map(&:name)
        items.each do |item|
          row = []
          row << item.email
          row << item.email_type
          row << item.created.strftime("%Y-%m-%d %H:%m")
          @columns.each do |column|
            row << item.in_data["#{column.id}"]
          end
          data << row
        end
      end
      send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
        filename: "ezine_members_#{Time.zone.now.to_i}.csv"
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

    def download
      export_csv
    end
end
