module Gws::Memo::NotificationFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_destroyed_item, only: [:destroy, :destroy_all]
    after_action :send_update_notification, only: [:create, :update]
    after_action :send_destroy_notification, only: [:destroy, :destroy_all]
  end

  private

  def send_update_notification
    return if request.get?
    return if response.code !~ /^3/

    users = @item.subscribed_users
    users = users.nin(id: @cur_user.id) if @cur_user
    return if users.blank?

    Gws::Memo::Notifier.deliver!(
      action: :update, cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: users, item: @item
    )
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def send_destroy_notification
    return if request.get?
    return if response.code !~ /^3/
    return if @destroyed_items.blank?

    @destroyed_items.each do |item, users|
      users = users.nin(id: @cur_user.id) if @cur_user
      next if users.blank?
      Gws::Memo::Notifier.deliver!(
        action: :destroy, cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
        to_users: users, item: item
      )
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def set_destroyed_item
    @destroyed_items = []
    if @item
      @destroyed_items << [@item.dup, @item.subscribed_users]
    end
    if @items.present?
      @items.each do |item|
        @destroyed_items << [item.dup, item.subscribed_users]
      end
    end
  end
end
