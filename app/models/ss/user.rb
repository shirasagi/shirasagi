class SS::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include SS::Reference::UserOccupations
  include Sys::Addon::Role
  include Sys::Reference::Role
  include Sys::Permission

  set_permission_name "sys_users", :edit

  def self.csv_headers
    headers = %w(
        id name kana uid organization_uid email password tel tel_ext type account_start_date account_expiration_date
        initial_password_warning session_lifetime restriction lock_state deletion_lock_state organization_id groups
        remark ss/locale_setting timezone ldap_dn
      )
    unless Sys::Auth::Setting.instance.mfa_otp_use_none?
      headers << "mfa_otp_enabled_at"
    end
    headers << "sys_roles"
    headers
  end

  def self.to_csv(opts = {})
    I18n.with_locale(I18n.default_locale) do
      CSV.generate(headers: true) do |csv|
        csv << csv_headers.map do |header|
          case header
          when 'ldap_dn'
            'DN'
          when 'ss/locale_setting'
            I18n.t("modules.addons.ss/locale_setting")
          when 'timezone'
            I18n.t("mongoid.attributes.ss/addon/locale_setting.timezone")
          else
            I18n.t("mongoid.attributes.ss/model/user.#{header}", default: header)
          end
        end

        opts[:criteria].each do |item|
          next if item.nil?
          csv << generate_csv_row(item)
        end
      end
    end
  end

  def self.generate_csv_row(item)
    row = []
    row << item.id
    row << item.name
    row << item.kana
    row << item.uid
    row << item.organization_uid
    row << item.email
    row << "" # password
    row << item.tel
    row << item.tel_ext
    row << (item.type.present? ? I18n.t("ss.options.user_type.#{item.type}") : nil)
    row << (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil)
    row << (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil)
    row << (item.initial_password_warning.present? ? I18n.t('ss.options.state.enabled') : I18n.t('ss.options.state.disabled'))
    row << item.session_lifetime
    row << (item.restriction.present? ? I18n.t("ss.options.restriction.#{item.restriction}") : nil)
    row << (item.lock_state.present? ? I18n.t("ss.options.user_lock_state.#{item.lock_state}") : nil)
    row << (item.deletion_lock_state.present? ? I18n.t("ss.options.user_deletion_lock_state.#{item.deletion_lock_state}") : nil)
    row << (item.organization ? item.organization.name : nil)
    row << item.groups.pluck(:name).join("\n")
    row << item.remark
    row << (item.lang.present? ? I18n.t("ss.options.lang.#{item.lang}") : nil)
    row << item.timezone
    row << item.ldap_dn
    unless Sys::Auth::Setting.instance.mfa_otp_use_none?
      row << (item.mfa_otp_secret.present? ? I18n.t("ss.mfa_otp_enabled_at", time: I18n.l(item.mfa_otp_enabled_at, format: :picker)) : I18n.t("ss.mfa_otp_not_enabled_yet"))
    end
    row << item.sys_roles.pluck(:name).join("\n")
    row
  end
end
