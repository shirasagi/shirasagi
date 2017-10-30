module Gws::GroupSetting::System
  extend ActiveSupport::Concern
  extend Gws::GroupSetting
  include SS::Model::EditorSetting
  include SS::Model::MailSetting

  included do
    field :sendmail_domains, type: SS::Extensions::Words
    field :canonical_scheme, type: String, default: 'http'
    field :canonical_domain, type: String

    permit_params :sendmail_domains, allow_email_domains: []
    permit_params :canonical_scheme, :canonical_domain
  end

  def allow_email_domains
    self[:sendmail_domains].presence || []
  end

  def email_domain_allowed?(email)
    return true if allow_email_domains.blank?
    domain = email.to_s.sub(/^.*@/, '')
    allow_email_domains.include?(domain)
  end

  def canonical_scheme_options
    [
      %w(http http),
      %w(https https),
    ]
  end
end
