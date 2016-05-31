class Inquiry::AnswersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter

  model Inquiry::Answer

  append_view_path "app/views/cms/pages"
  navi_view "inquiry/main/navi"

  private
    def fix_params
      { cur_site: @cur_site, cur_node: @cur_node }
    end

    def send_csv(items)
      require "csv"

      columns = @cur_node.becomes_with_route("inquiry/form").columns.pluck(:name)
      headers = %w(id)
      headers += columns
      headers += %w(created source_url source_name)
      csv = CSV.generate do |data|
        data << headers
        items.each do |item|
          item.attributes = fix_params
          values = item.data.map{|d| [d.column.name, d.value]}.to_h

          row = []
          row << item.id
          columns.each do |col|
            row << values[col]
          end
          row << item.updated.strftime("%Y/%m/%d %H:%M")
          row << item.source_full_url
          row << item.source_name

          data << row
        end
      end

      send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
        filename: "inquiry_answers_#{Time.zone.now.to_i}.csv"
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

    def show
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      render
    end

    def delete
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def destroy
      raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
      render_destroy @item.destroy
    end

    def download
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        search(params[:s]).
        order_by(updated: -1)
      send_csv @items
    end
end
