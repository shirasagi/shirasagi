module Gws::Memo::NotificationFilter
  extend ActiveSupport::Concern

  included do
    after_action :send_notification, only: %i[create update]
  end

  private

  def send_notification
    return if request.get?
    return if response.code !~ /^3/

    users = @item.subscribed_users
    return if users.blank?

    Gws::Memo::Notifier.deliver!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: users, item: @item
    )
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
