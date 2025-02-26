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
    csv_headers.map do |header|
      case header
      when "password"
        ""
      when "mfa_otp_enabled_at"
        if item.mfa_otp_secret.present?
          I18n.t("ss.mfa_otp_enabled_at", time: I18n.l(item.mfa_otp_enabled_at, format: :picker))
        else
          I18n.t("ss.mfa_otp_not_enabled_yet")
        end
      when "sys_roles"
        item.sys_roles.pluck(:name).join("\n")
      when "account_start_date", "account_expiration_date"
        item.try(header).present? ? I18n.l(item.try(header)) : nil
      when "initial_password_warning"
        item.initial_password_warning.present? ? I18n.t('ss.options.state.enabled') : I18n.t('ss.options.state.disabled')
      when "type"
        item.try(header).present? ? I18n.t("ss.options.user_type.#{item.try(header)}") : nil
      when "restriction"
        item.try(header).present? ? I18n.t("ss.options.restriction.#{item.try(header)}") : nil
      when "lock_state"
        item.try(header).present? ? I18n.t("ss.options.user_lock_state.#{item.try(header)}") : nil
      when "deletion_lock_state"
        item.try(header).present? ? I18n.t("ss.options.user_deletion_lock_state.#{item.try(header)}") : nil
      when "organization_id"
        item.organization&.name
      when "groups"
        item.groups.pluck(:name).join("\n")
      when "ss/locale_setting"
        item.try(:lang).present? ? I18n.t("ss.options.lang.#{item.try(:lang)}") : nil
      when "ss/addon/locale_setting.timezone"
        (item.try(:timezone).presence)
      else
        item.try(header)
      end
    end
  end
end
