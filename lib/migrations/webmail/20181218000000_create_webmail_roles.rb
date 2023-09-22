class SS::Migration20181218000000
  include SS::Migration::Base

  depends_on "20181214000000"

  def change
    return if Webmail::Role.count > 0

    webmail_r01 = Webmail::Role.new(
      name: I18n.t('webmail.roles.admin'), permissions: Webmail::Role.permission_names, permission_level: 3
    )
    webmail_r01.without_record_timestamps { webmail_r01.save! }

    user_ids = Webmail::User.pluck(:id)
    user_ids.each do |id|
      user = Webmail::User.find(id) rescue nil
      next unless user

      user.add_to_set(webmail_role_ids: webmail_r01.id)
    end
  end
end
