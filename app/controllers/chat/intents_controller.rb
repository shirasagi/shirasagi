class Chat::IntentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chat::Intent

  navi_view "cms/node/main/navi"

  private

  def set_crumbs
    @crumbs << [@model.model_name.human, action: :index]
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user, node_id: @cur_node.id }
  end

  def pre_params
    { name: params[:name], phrase: params[:name] }
  end

  public

  def index
    set_items
    @items = @items.in(category_ids: params.dig(:s, :category_id).try(:to_i)) if params.dig(:s, :category_id).present?
    @items = @items.allow(:read, @cur_user, site: @cur_site).
      where(node_id: @cur_node.id).
      search(params[:s]).
      order_by(order: 1, name: 1, updated: -1).
      page(params[:page]).
      per(50)
  end

  def download
    csv = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      where(node_id: @cur_node).
      order_by(order: 1, name: 1, updated: -1).csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "chat_intents_#{Time.zone.now.to_i}.csv"
  end

  def import
    @item = @model.new
    return if request.get?

    begin
      file = params[:item].try(:[], :file)
      raise I18n.t("errors.messages.invalid_csv") if file.nil? || ::File.extname(file.original_filename) != ".csv"
      CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')

      # save csv to use in job
      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.model = "chat/intent"
      ss_file.save

      # call job
      Chat::Intent::ImportJob.bind(site_id: @cur_site, node_id: @cur_node).perform_later(ss_file.id)
      flash.now[:notice] = I18n.t("ss.notice.started_import")
    rescue => e
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @item.errors.add :base, e.to_s
    end
  end
end
