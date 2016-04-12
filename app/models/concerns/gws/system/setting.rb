module Gws::System::Setting
  extend ActiveSupport::Concern
  extend Gws::Setting

  included do
    field :sendmail_domains, type: SS::Extensions::Words

    permit_params :sendmail_domains, allow_email_domains: []
  end

  def allow_email_domains
    self[:sendmail_domains].presence || []
  end

  def email_domain_allowed?(email)
    return true if allow_email_domains.blank?
    domain = email.to_s.sub(/^.*@/, '')
    allow_email_domains.include?(domain)
  end
end
