class SS::Migration20181015000000
  include SS::Migration::Base

  depends_on "20181009202100"

  DEFAULT_PERMISSIONS = %w(use_cms use_gws use_webmail).freeze

  def change
    all_ids = Sys::Role.all.pluck(:id)
    all_ids.each_slice(20) do |ids|
      roles = Sys::Role.all.in(id: ids).to_a
      roles.each do |role|
        next if (DEFAULT_PERMISSIONS - role.permissions).blank?

        role.permissions += DEFAULT_PERMISSIONS
        role.permissions.uniq!
        role.without_record_timestamps { role.save! }
      end
    end

    default_sys_role = nil
    all_ids = SS::User.all.pluck(:id)
    all_ids.each_slice(20) do |ids|
      users = SS::User.all.in(id: ids).to_a
      users.each do |user|
        next if user.sys_roles.present?

        default_sys_role ||= begin
          role = Sys::Role.where(name: I18n.t('sys.roles.user')).first
          if role.blank?
            role = Sys::Role.create name: I18n.t('sys.roles.user'), permissions: DEFAULT_PERMISSIONS
          end
          role
        end

        user.sys_role_ids = [ default_sys_role.id ]
        user.without_record_timestamps { user.save! }
      end
    end
  end
end
