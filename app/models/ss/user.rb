class SS::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include SS::Reference::UserOccupations
  include Sys::Addon::Role
  include Sys::Reference::Role
  include Sys::Permission

  set_permission_name "sys_users", :edit

  class << self
    def csv_headers
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

    def to_csv(opts = {})
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

            begin
              csv << generate_csv_row(item)
            rescue => e
              Rails.logger.error{ "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
            end
          end
        end
      end
    end

    def generate_csv_row(item)
      row = generate_basic_row(item)
      row << generate_mfa_field(item) unless Sys::Auth::Setting.instance.mfa_otp_use_none?
      row << item.sys_roles.pluck(:name).join("\n")
      row
    end

    private

    def generate_basic_row(item)
      [
        item.id,
        item.name,
        item.kana,
        item.uid,
        item.organization_uid,
        item.email,
        "", # password は出力しない
        item.tel,
        item.tel_ext,
        (item.type.present? ? I18n.t("ss.options.user_type.#{item.type}") : nil),
        (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil),
        (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil),
        (item.initial_password_warning.present? ? I18n.t("ss.options.state.enabled") : I18n.t("ss.options.state.disabled")),
        item.session_lifetime,
        (item.restriction.present? ? I18n.t("ss.options.restriction.#{item.restriction}") : nil),
        (item.lock_state.present? ? I18n.t("ss.options.user_lock_state.#{item.lock_state}") : nil),
        (item.deletion_lock_state.present? ? I18n.t("ss.options.user_deletion_lock_state.#{item.deletion_lock_state}") : nil),
        (item.organization ? item.organization.name : nil),
        item.groups.pluck(:name).join("\n"),
        item.remark,
        (item.lang.present? ? I18n.t("ss.options.lang.#{item.lang}") : nil),
        item.timezone,
        item.ldap_dn
      ]
    end

    def generate_mfa_field(item)
      if item.mfa_otp_secret.present?
        I18n.t("ss.mfa_otp_enabled_at", time: I18n.l(item.mfa_otp_enabled_at, format: :picker))
      else
        I18n.t("ss.mfa_otp_not_enabled_yet")
      end
    end
  end
end
