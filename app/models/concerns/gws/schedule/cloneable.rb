module Gws::Schedule::Cloneable
  extend ActiveSupport::Concern
  extend SS::Translation

  def new_clone(attributes = {})
    attributes = self.attributes.merge(attributes).select { |k| self.fields.keys.include?(k) }

    item = self.class.new(attributes)
    item.id = nil
    item.created = nil
    item.user_id = nil
    item.user_uid = nil
    item.user_name = nil
    item.cur_user = @cur_user
    item.cur_site = @cur_site
    item
  end
end
