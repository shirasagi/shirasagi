module Gws::Memo::NotificationFilter
  extend ActiveSupport::Concern

  included do
    cattr_accessor :destroy_notification_actions, :destroy_all_notification_actions
    self.destroy_notification_actions = [:destroy, :soft_delete]
    self.destroy_all_notification_actions = [:destroy_all, :soft_delete_all]

    before_action :set_destroyed_item, if: :check_destroy_notification_action
    before_action :set_destroyed_items, if: :check_destroy_all_notification_action

    after_action :send_update_notification, only: [:create, :update, :publish]
    after_action :send_undo_delete_notification, only: [:undo_delete]
    after_action :send_destroy_notification, if: ->{ check_destroy_notification_action || check_destroy_all_notification_action }
  end

  private

  def check_destroy_notification_action(*args)
    actions = self.class.destroy_notification_actions.map(&:to_s)
    actions.include?(params[:action])
  end

  def check_destroy_all_notification_action(*args)
    actions = self.class.destroy_all_notification_actions.map(&:to_s)
    actions.include?(params[:action])
  end

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
      users = users.select { |user| user.use_notice?(@item) }

      return if users.blank?
    end

    Gws::Memo::Notifier.deliver!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: users, item: @item, subject: subject, text: text
    )
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def send_undo_delete_notification
    return if request.get?
    return if @item.errors.present?
    return unless @cur_site.notify_model?(@item.class)
    return unless item_notify_enabled?(@item)

    if @item.class.name.include?("Gws::Monitor")
      users = []
    else
      users = @item.subscribed_users
      users = users.nin(id: @cur_user.id) if @cur_user
      users = users.select { |user| user.use_notice?(@item) }

      return if users.blank?
    end

    Gws::Memo::Notifier.deliver!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: users, item: @item, action: "undo_delete"
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

    check = []
    @destroyed_items.each do |item, users|
      next unless @cur_site.notify_model?(item.class)
      next unless item_notify_enabled?(item)

      check_key = [ item.class.name, item.id.to_s ].join(":")
      next if check.include?(check_key)

      check << check_key
      send_destroy_notification_one(item, users)
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def set_destroyed_item
    return if request.get?
    return if @item.blank?

    if @item.class.name.include?("Gws::Monitor")
      @destroyed_item = [@item.dup, []]
    elsif @item && @item.class.name.include?("Gws::Schedule::Todo")
      @destroyed_item = [@item, @item.subscribed_users]
    else
      copy = @item.dup
      # if id is BSON::ObjectID, it is needed to restore id because id is changed during duplicating object.
      copy.id = @item.id
      @destroyed_item = [copy, @item.subscribed_users]
    end
  end

  def set_destroyed_items
    return if request.get?

    if @items.present?
      @destroyed_items ||= []
      @items.each do |item|
        if item.class.name.include?("Gws::Monitor")
          @destroyed_items << [item.dup, []]
        elsif item.class.name.include?("Gws::Schedule::Todo")
          @destroyed_items << [item, item.subscribed_users]
        else
          copy = item.dup
          # if id is BSON::ObjectID, it is needed to restore id because id is changed during duplicating object.
          copy.id = item.id
          @destroyed_items << [copy, item.subscribed_users]
        end
      end
    end
  end

  def item_notify_enabled?(item)
    case item.model_name.i18n_key
    when :"gws/board/post"
      return item.topic.notify_enabled? && item.topic.public?
    when :"gws/schedule/comment"
      return item.schedule.notify_enabled?
    when :"gws/schedule/attendance"
      return item._parent.notify_enabled?
    else
      notifiable = item.respond_to?(:notify_enabled?) ? item.notify_enabled? : true
      public = item.respond_to?(:public?) ? item.public? : true

      notifiable && public
    end
  end

  def send_destroy_notification_one(item, users)
    if !item.class.name.include?("Gws::Monitor")
      users = users.nin(id: @cur_user.id) if @cur_user
      users = users.select { |user| user.use_notice?(item) }
      return if users.blank?
    end

    i18n_key = item.class.model_name.i18n_key

    if item.try(:topic).try(:name).present?
      name = item.topic.name
    elsif item.try(:_parent).try(:name).present?
      name = item._parent.name
    elsif item.try(:parent).try(:name).present?
      name = item.parent.name
    elsif item.try(:schedule).try(:name).present?
      name = item.schedule.name
    elsif item.try(:todo).try(:name).present?
      name = item.todo.name
    elsif item.try(:name).present?
      name = item.name
    else
      name = ''
    end

    subject = I18n.t("gws_notification.#{i18n_key}/destroy.subject", name: name)
    if !item.try(:_parent).present? && !item.try(:parent).present? && !item.try(:schedule).present? && !item.try(:todo).present?
      text = I18n.t("gws_notification.#{i18n_key}/destroy.text", name: name)
    end

    Gws::Memo::Notifier.deliver!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: users, item: item, subject: subject, text: text
    )
  end
end
