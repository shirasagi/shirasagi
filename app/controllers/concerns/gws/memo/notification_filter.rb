module Gws::Memo::NotificationFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_destroyed_item, only: [:destroy, :soft_delete]
    before_action :set_destroyed_items, only: [:destroy_all, :soft_delete_all]

    after_action :send_update_notification, only: [:create, :update, :publish]
    after_action :send_destroy_notification, only: [:destroy, :destroy_all, :soft_delete, :soft_delete_all]
  end

  private

  def send_update_notification(subject = nil, text = nil)
    return if request.get?
    #return if response.code !~ /^3/
    return if @item.errors.present?
    return unless @cur_site.notify_model?(@item.class)

    return unless item_notify_enabled?(@item)

    if @item.class.name.include?("Gws::Monitor")
      users = []
    else
      users = @item.subscribed_users
      users = users.nin(id: @cur_user.id) if @cur_user
      users = users.select{|user| user.use_notice?(@item)}

      return if users.blank?
    end

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

    @destroyed_items ||= []
    @destroyed_items << @destroyed_item if @destroyed_item
    return if @destroyed_items.blank?

    @destroyed_items.each do |item, users|
      next unless @cur_site.notify_model?(item) || item_notify_enabled?(item)

      if !item.class.name.include?("Gws::Monitor")
        users = users.nin(id: @cur_user.id) if @cur_user
        users = users.select{|user| user.use_notice?(item)}
        next if users.blank?
      end

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

    if @item && @item.class.name.include?("Gws::Monitor")
      @destroyed_item = [@item.dup, []]
    elsif @item
      @destroyed_item = [@item.dup, @item.subscribed_users]
    end
  end

  def set_destroyed_items
    return if request.get?

    if @items.present?
      @destroyed_items ||= []
      @items.each do |item|
        if item.class.name.include?("Gws::Monitor")
          @destroyed_items << [item.dup, []]
        else
          @destroyed_items << [item.dup, item.subscribed_users]
        end
      end
    end
  end

  def item_notify_enabled?(item)
    case item.model_name.i18n_key
    when :"gws/board/post"
      return item.topic.notify_enabled?
    when :"gws/schedule/comment"
      return item.schedule.notify_enabled?
    when  :"gws/schedule/attendance"
      return item._parent.notify_enabled?
    else
      if item.respond_to?(:notify_enabled?)
        return item.notify_enabled?
      else
        return true
      end
    end
  end
end
