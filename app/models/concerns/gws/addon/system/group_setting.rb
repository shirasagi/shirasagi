module Gws::Addon::System::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include SS::Model::EditorSetting
  include SS::Model::MailSetting

  set_addon_type :organization

  included do
    field :sendmail_domains, type: SS::Extensions::Words
    field :canonical_scheme, type: String, default: 'http'
    field :canonical_domain, type: String
    field :trash_threshold, type: Integer, default: 1
    field :trash_threshold_unit, type: String, default: 'year'

    permit_params :sendmail_domains, allow_email_domains: []
    permit_params :canonical_scheme, :canonical_domain, :trash_threshold, :trash_threshold_unit
  end

  def allow_email_domains
    self[:sendmail_domains].presence || []
  end

  def email_domain_allowed?(email)
    return true if allow_email_domains.blank?

    domain = Mail::Address.new(email).domain rescue nil
    return true if domain.blank?

    allow_email_domains.include?(domain)
  end

  def exclude_disallowed_emails(emails)
    emails.filter_map { |email| exclude_disallowed_email(email) }
  end

  def exclude_disallowed_email(email)
    return nil if email.blank?
    return email if email_domain_allowed?(email)
    Rails.logger.warn("exclude disallowed email : #{email}")
    nil
  end

  def canonical_scheme_options
    [
      %w(http http),
      %w(https https),
    ]
  end

  def trash_threshold_unit_options
    %w(day week month year).collect do |unit|
      [I18n.t("ss.options.datetime_unit.#{unit}"), unit]
    end
  end
end
