module Gws::Workload::NotificationFilter
  extend ActiveSupport::Concern
  include Gws::Memo::NotificationFilter

  included do
    self.destroy_notification_actions = [:soft_delete]
    self.destroy_all_notification_actions = [:soft_delete_all]

    #after_action :send_finish_notification, only: [:finish]
    #after_action :send_revert_notification, only: [:revert]
    #after_action :send_finish_all_notification, only: [:finish_all]
    #after_action :send_revert_all_notification, only: [:revert_all]
  end

  private

  def set_destroyed_item
    set_item unless @item
    super
  end

  def set_destroyed_items
    set_selected_items unless @selected_items
    super
  end
end
