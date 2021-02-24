class Inquiry::AnswersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  include Inquiry::AnswersFilter

  navi_view "inquiry/main/navi"

  before_action :check_permission

  private

  def fix_params
    { cur_site: @cur_site, cur_node: @cur_node }
  end

  def check_permission
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_items
    @state = params.dig(:s, :state).presence || "unclosed"

    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(node_id: @cur_node.id).
      search(params[:s]).
      state(@state)
  end

  def send_csv(items)
    require "csv"

    # columns = @cur_node.becomes_with_route("inquiry/form").columns.order_by(order: 1).to_a
    headers = %w(id state comment).map { |key| @model.t(key) }
    headers += columns.map(&:name)
    headers += %w(source_url source_name inquiry_page_url inquiry_page_name created updated).map { |key| @model.t(key) }
    csv = CSV.generate do |data|
      data << headers
      items.each do |item|
        item.attributes = fix_params

        values = {}
        columns.each do |column|
          answer_data = item.data.select { |answer_data| answer_data.column_id == column.id }.first
          values[column.id] = answer_data.value if answer_data
        end

        row = []
        row << item.id
        row << (item.label :state)
        row << item.comment
        columns.each do |column|
          row << values[column.id]
        end
        row << item.source_full_url
        row << item.source_name
        row << item.inquiry_page_full_url
        row << item.inquiry_page_name
        row << item.created.strftime("%Y/%m/%d %H:%M")
        row << item.updated.strftime("%Y/%m/%d %H:%M")

        data << row
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
              filename: "inquiry_answers_#{Time.zone.now.to_i}.csv"
  end

  public

  def download
    @state = params.dig(:s, :state).presence || "unclosed"
    @items = @items.order_by(updated: -1)
    send_csv @items
  end
end
