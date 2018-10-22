module Gws::Memo::NotificationFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_destroyed_item, only: [:destroy, :soft_delete]
    before_action :set_destroyed_items, only: [:destroy_all, :soft_delete_all]

    after_action :send_update_notification, only: [:create, :update]
    after_action :send_destroy_notification, only: [:destroy, :destroy_all, :soft_delete, :soft_delete_all]
  end

  private

  def send_update_notification(subject = nil, text = nil)
    return if request.get?
    #return if response.code !~ /^3/
    return if @item.errors.present?
    return unless @cur_site.notify_model?(@item.class)

    if @item.respond_to?(:notify_enabled?)
      return unless @item.notify_enabled?
    end

    users = @item.subscribed_users
    users = users.nin(id: @cur_user.id) if @cur_user
    users = users.select{|user| user.use_notice?(@item)}

    return if users.blank?

    Gws::Memo::Notifier.deliver!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: users, item: @item, subject: subject, text: text
    )
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def send_destroy_notification
    return if request.get?
    return if response.code !~ /^3/
    return unless @cur_site.notify_model?(@item.class)

    @destroyed_items ||= []
    @destroyed_items << @destroyed_item if @destroyed_item
    return if @destroyed_items.blank?

    @destroyed_items.each do |item, users|
      if item.respond_to?(:notify_enabled?)
        next unless item.notify_enabled?
      end

      users = users.nin(id: @cur_user.id) if @cur_user
      users = users.select{|user| user.use_notice?(item)}
      next if users.blank?

      i18n_key = item.class.model_name.i18n_key

      if item.try(:_parent).try(:name).present?
        name = item._parent.name
      elsif item.try(:parent).try(:name).present?
        name = item.parent.name
      elsif item.try(:schedule).try(:name).present?
        name = item.schedule.name
      elsif item.try(:name).present?
        name = item.name
      else
        name = ''
      end

      subject = I18n.t("gws_notification.#{i18n_key}/destroy.subject", name: name)
      if !item.try(:_parent).present? && !item.try(:parent).present? && !item.try(:schedule).present?
        text = I18n.t("gws_notification.#{i18n_key}/destroy.text", name: name)
      end

      Gws::Memo::Notifier.deliver!(
        cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
        to_users: users, item: item, subject: subject, text: text
      )
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def set_destroyed_item
    return if request.get?

    if @item
      @destroyed_item = [@item.dup, @item.subscribed_users]
    end
  end

  def set_destroyed_items
    return if request.get?

    if @items.present?
      @destroyed_items ||= []
      @items.each do |item|
        @destroyed_items << [item.dup, item.subscribed_users]
      end
    end
  end
end
