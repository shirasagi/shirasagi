class Cms::GenerationReport::HistoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/generation_report/main/navi"

  model Cms::GenerationReport::History

  before_action :set_model

  helper_method :title, :item_title, :format_elapsed

  private

  def title
    @title ||= Cms::GenerationReport::Title.site(@cur_site).find(params[:title])
  end

  def set_model
    @model = Cms::GenerationReport::History[title]
  end

  def set_item
    set_model
    super
  end

  def item_title(item)
    title = "[#{item.history_type}] #{item.content_name}"
    if item.content_filename
      title = "#{title} (#{item.content_filename})"
    end
    title
  end

  def format_elapsed(elapsed)
    return unless elapsed
    I18n.t("datetime.distance_in_words.x_seconds", count: elapsed.round(3))
  end

  public

  def download_all
    @item = SS::DownloadParam.new
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    set_items
    enumerable = @items.enum_csv(cur_site: @cur_site, encoding: @item.encoding)
    send_enum enumerable, filename: "cms_generation_report_histories_#{Time.zone.now.to_i}.csv"
  end
end
