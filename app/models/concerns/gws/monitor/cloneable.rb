module Gws::Monitor::Cloneable
  extend ActiveSupport::Concern
  extend SS::Translation

  def new_clone
    item = clone
    prefix = I18n.t("workflow.cloned_name_prefix")
    item.id = nil
    item.created = nil
    item.user_id = nil
    item.user_uid = nil
    item.user_name = nil
    item.state = "draft"
    item.answer_state_hash = {}
    item.cur_user = @cur_user
    item.cur_site = @cur_site
    item.in_clone_file = true
    item
  end
end
