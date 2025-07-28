class Chat::HistoriesController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter

  model Chat::History

  navi_view "cms/node/main/navi"

  private

  def set_crumbs
    @crumbs << [@model.model_name.human, action: :index]
  end

  def cond
    { site_id: @cur_site.id, node_id: @cur_node.id }
  end

  def send_csv(items)
    headers = %w(id session_id request_id text question result suggest click_suggest node_id prev_intent_id intent_id)
    headers.map! { |key| @model.t(key) }
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << headers
        items.each do |item|
          row = []
          row << item.id
          row << item.session_id
          row << item.request_id
          row << item.text
          row << item.question
          row << item.result
          row << item.suggest
          row << item.click_suggest
          row << item.node.try(:name)
          row << item.prev_intent.try(:name)
          row << item.intent.try(:name)

          data << row
        end
      end
    end

    send_data csv.encode("SJIS", invalid: :replace, undef: :replace),
      filename: "chat_history_#{Time.zone.now.to_i}.csv"
  end

  public

  def index
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    @items = @model.where(cond).
      search(params[:s]).
      order_by(created: -1).
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
    @items = @model.where(cond).
      search(params[:s]).
      order_by(created: -1)
    send_csv @items
  end
end
