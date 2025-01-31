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
      CSV.generate(headers: true) do |csv|
        csv << SS::User.csv_headers.map { |header| I18n.t("mongoid.attributes.ss/model/user.#{header}", default: header) }

        opts[:criteria].each do |item|
          next if item.nil?

          row = SS::User.csv_headers.map do |header|
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
            when "organization_id"
              item.organization&.name
            when "groups"
              item.groups.pluck(:name).join("\n")
            else
              item.try(header)
            end
          end

          csv << row
        end
      end
    end
  end
end
