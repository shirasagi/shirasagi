class SS::Migration20250124000000
  include SS::Migration::Base

  def change
    Gws::Role.each do |item|
      permissions = item.permissions.to_a
      next if permissions.include?("edit_gws_memo_notice_user_setting")

      permissions << "edit_gws_memo_notice_user_setting"
      item.permissions = permissions
      item.update
    end
  end
end
