module Gws::Schedule::Cloneable
  extend ActiveSupport::Concern
  extend SS::Translation

  def new_clone
    attributes = self.attributes.except(
      "id", "_id", "created", "user_id", "user_uid", "user_name", "todo_state", "achievement_rate")
    item = ::Mongoid::Factory.from_db(self.class, attributes)
    item.instance_variable_set(:@new_record, true)
    item.cur_user = @cur_user
    item.cur_site = @cur_site
    item.name = "[#{I18n.t("workflow.cloned_name_prefix")}] #{item.name}"
    item.in_clone_file = true
    item
  end
end
