module Gws::Notice::Cloneable
  extend ActiveSupport::Concern
  extend SS::Translation

  def new_clone
    item = clone
    item.id = nil
    item.created = nil
    item.user_id = nil
    item.user_uid = nil
    item.user_name = nil
    item.cur_user = @cur_user
    item.cur_site = @cur_site
    item.in_clone_file = true
    item.name = I18n.t('gws/notice.prefix.copy') + item.name
    item
  end
end
