# coding: utf-8
module History::LogFilter
  extend ActiveSupport::Concern

  included do
    after_action :put_log, if: ->{ !request.get? }
  end

  private
    def put_log
      log = History::Log.new
      log.url        = request.path
      log.controller = params[:controller]
      log.action     = params[:action]
      log.user_id    = @cur_user.id
      log.site_id    = @cur_site.id if @cur_site
      log.item_id    = @item.id if @item
      log.item_class = @item.class if @item
      log.save
      return
    end
end
