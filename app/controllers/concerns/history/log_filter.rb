module History::LogFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:log_class, instance_accessor: false) { History::Log }
    after_action :put_history_log
  end

  private

  def put_history_log
    self.class.log_class.create_controller_log!(
      request, response,
      controller: params[:controller], action: params[:action],
      cur_site: @cur_site, cur_user: @cur_user, item: @item
    ) rescue nil
  end
end
