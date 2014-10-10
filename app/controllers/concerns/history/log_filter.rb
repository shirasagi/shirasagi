module History::LogFilter
  extend ActiveSupport::Concern

  private
    def put_history_log
      log = History::Log.new
      log.url          = request.path
      log.controller   = params[:controller]
      log.action       = params[:action]
      log.user_id      = @cur_user.id
      log.site_id      = @cur_site.id if @cur_site

      if @item && @item.respond_to?(:new_record?)
        if !@item.new_record?
          log.target_id    = @item.id
          log.target_class = @item.class
        end
      end

      log.save
    end
end
