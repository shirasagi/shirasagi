class SS::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include SS::Reference::UserOccupations
  include Sys::Addon::Role
  include Sys::Reference::Role
  include Sys::Permission

  set_permission_name "sys_users", :edit

  require 'csv'

  def self.csv_headers
    headers = %w(
          id name kana uid organization_uid email password tel tel_ext account_start_date account_expiration_date
          initial_password_warning organization_id groups last_loggedin)
    unless Sys::Auth::Setting.instance.mfa_otp_use_none?
      headers << "mfa_otp_enabled_at"
    end
    headers << "sys_roles"
    headers
  end

  def self.to_csv(opts = {})
    I18n.with_locale(I18n.default_locale) do
      CSV.generate(headers: true) do |data|
        data << csv_headers.map { |k| I18n.t("mongoid.attributes.ss/model/user.#{k}", default: k) }

        opts[:criteria].each do |item|
          line = []
          line << item.id
          line << item.name
          line << item.kana
          line << item.uid
          line << item.organization_uid
          line << item.email
          line << nil # パスワード
          line << item.tel
          line << item.tel_ext
          line << (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil)
          line << (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil)
          line << if item.initial_password_warning.present?
                    I18n.t('ss.options.state.enabled')
                  else
                    I18n.t('ss.options.state.disabled')
                  end
          line << item.organization&.name
          line << (item.groups.pluck(:name).join("\n") || '')
          line << item.last_loggedin
          unless Sys::Auth::Setting.instance.mfa_otp_use_none?
            if item.mfa_otp_secret.present?
              term = I18n.t("ss.mfa_otp_enabled_at", time: I18n.l(item.mfa_otp_enabled_at, format: :picker))
            else
              term = I18n.t("ss.mfa_otp_not_enabled_yet")
            end
            line << term
          end
          line << item.sys_roles.pluck(:name).join("\n")
          data << line
        end
      end
    end
  end
end
