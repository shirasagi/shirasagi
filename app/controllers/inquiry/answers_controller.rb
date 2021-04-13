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

    columns = @cur_node.becomes_with_route("inquiry/form").columns.order_by(order: 1).to_a
    headers = %w(id state comment).map { |key| @model.t(key) }
    headers += columns.map(&:name)
    headers += %w(source_url source_name created).map { |key| @model.t(key) }
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
        row << item.updated.strftime("%Y/%m/%d %H:%M")

        data << row
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
      filename: "inquiry_answers_#{Time.zone.now.to_i}.csv"
  end

  def send_afile(file)
    filedata = []
    filepath = file.path
    File.open(filepath, 'rb') do |of|
      filedata = of.read
    end
    if filedata.present? || !filedata.nil?
      send_data(filedata, :filename => file.name)
    end
  end

  public

  def index
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

    @state = params.dig(:s, :state).presence || "unclosed"
    @items = @model.site(@cur_site).
      where(node_id: @cur_node.id).
      search(params[:s]).
      state(@state).
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

    @state = params.dig(:s, :state).presence || "unclosed"
    @items = @model.site(@cur_site).
      where(node_id: @cur_node.id).
      search(params[:s]).
      state(@state).
      order_by(updated: -1)
    send_csv @items
  end

  def download_afile
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    if params[:id]

      client_name = Inquiry::Answer.persistence_context.send(:client_name)
      file = SS::File.with(client: client_name) do |model|
        model.where(id: params[:fid].to_i).first
      end
      unless file.blank?
        send_afile file
      end
      return
    end
  end
end
