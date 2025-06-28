module Inquiry2::AnswersFilter
  extend ActiveSupport::Concern

  included do
    model Inquiry2::Answer

    append_view_path "app/views/inquiry2/answers"
    append_view_path "app/views/cms/pages"

    before_action :set_items, only: %i[index download]
  end

  private

  def set_items
    # must be overridden by sub-class
  end

  def send_csv(items)
    require "csv"

    columns = (@cur_inquiry2_form || @cur_node).becomes_with_route("inquiry2/form").columns.order_by(order: 1).to_a
    headers = %w(id state comment).map { |key| @model.t(key) }
    headers += columns.map(&:name)
    headers += %w(source_url source_name inquiry2_page_url inquiry2_page_name created updated).map { |key| @model.t(key) }
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << headers
        items.each do |item|
          item.attributes = fix_params

          values = {}
          columns.each do |column|
            column_value = item.column_values.find { |v| column.id == v.column_id }
            values[column.id] = column_value.try(:value)
          end

          row = []
          row << item.id
          row << (item.label :state)
          row << item.comment
          columns.each do |column|
            row << values[column.id]
          end
          row << item.source_full_url # ページURL
          row << item.source_name
          row << item.inquiry2_page_full_url # お問い合わせページURL
          row << item.inquiry2_page_name
          row << I18n.l(item.created, format: :picker)
          row << I18n.l(item.updated, format: :picker)

          data << row
        end
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
      filename: "inquiry2_answers_#{Time.zone.now.to_i}.csv"
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
    if params[:s].present? && params[:s][:group].present?
      @group = Cms::Group.site(@cur_site).active.find(params[:s][:group])
    end
    @groups = Cms::Group.site(@cur_site).active.tree_sort

    @items = @items.order_by(updated: -1).page(params[:page]).per(50)
  end

  def download
    @state = params.dig(:s, :state).presence || "unclosed"
    @items = @items.order_by(updated: -1)
    send_csv @items
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    raise "400" if @selected_items.blank?

    entries = @selected_items
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def download_afile
    raise "404" if params[:id].blank?

    client_name = Inquiry2::Answer.persistence_context.send(:client_name)
    file = SS::File.with(client: client_name) do |model|
      model.where(id: params[:fid].to_i).first
    end
    send_afile file if file.present?
  end
end
