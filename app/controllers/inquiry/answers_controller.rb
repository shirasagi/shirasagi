class Inquiry::AnswersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter

  model Inquiry::Answer

  append_view_path "app/views/cms/pages"
  navi_view "inquiry/main/navi"

  private
    def send_csv(items)
      require "csv"

      columns = @cur_node.becomes_with_route("inquiry/form").columns.pluck(:name)
      csv = CSV.generate do |data|
        data << columns
        items.each do |item|
          values = item.data.map{|d| [d.column.name, d.value]}.to_h

          row = []
          columns.each do |col|
            row << values[col]
          end

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
      send_csv @cur_node.becomes_with_route("inquiry/form").answers
    end
end
