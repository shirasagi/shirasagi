module Cms::RedirectPage
  extend ActiveSupport::Concern

  included do
    field :redirect_link, type: String
    permit_params :redirect_link

    before_validation :normalize_redirect_link
    validates :redirect_link, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
    validates :redirect_link, url: { absolute_path: true, relative_path: true, allow_blank: true },
              unless: ->{ Sys::TrustedUrlValidator.url_restricted? }
    validate :encode_redirect_link
  end

  def effective_redirect_link
    ret = try(:redirect_link).presence rescue nil
    return ret if ret.blank?
    return nil unless UrlValidator.valid?(ret, absolute_path: true, relative_path: true)

    s = @cur_site || (try(:site) rescue nil)
    return nil unless s.try(:redirect_link_enabled?)
    return nil if Sys::TrustedUrlValidator.url_restricted? && !Cms.trusted_url?(s, ret)

    ret
  end

  def view_layout
    effective_redirect_link.present? ? "cms/redirect" : "cms/page"
  end

  private

  def normalize_redirect_link
    self.redirect_link = redirect_link.to_s.strip if redirect_link
  end

  def encode_redirect_link
    return if errors[:redirect_link].present?
    return unless redirect_link_changed?
    return if redirect_link.blank?

    uri = Addressable::URI.parse(redirect_link)

    if uri.scheme.nil?
      uri = Addressable::URI.join((@cur_site || site).root_url, uri)
    end

    self.redirect_link = SS.follow_up_url_encode!(uri)
  rescue => e
    logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    errors.add :redirect_link, :url
  end
end
