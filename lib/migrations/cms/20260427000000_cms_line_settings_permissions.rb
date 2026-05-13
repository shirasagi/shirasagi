class SS::Migration20260427000000
  include SS::Migration::Base

  def change
    message_permission = "use_other_cms_line_messages"
    setting_permission = "use_cms_line_settings"

    Cms::Role.in(permissions: message_permission).each do |item|
      item.add_to_set(permissions: setting_permission)
    end
  end
end
