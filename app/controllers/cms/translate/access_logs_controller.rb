class Cms::Translate::AccessLogsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Translate::AccessLog
  navi_view "cms/translate/main/navi"

  public

  def download
    @item = Translate::DownloadParam.new
    @item.save_term = '1.day'
    return if request.get? || request.head?

    @item.attributes = params.require(:item).permit(:encoding, :save_term)
    if @item.invalid?
      render
      return
    end

    cond = { site_id: @cur_site.id }
    items = @model.where(cond)
    @item.save_term_in_time.try do |from|
      items = items.gte(created: from)
    end
    items = items.reorder(created: 1)

    enumerable = items.enum_csv(cur_site: @cur_site, encoding: @item.encoding)
    filename = "translate_access_logs_#{Time.zone.now.to_i}.csv"

    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end
end
