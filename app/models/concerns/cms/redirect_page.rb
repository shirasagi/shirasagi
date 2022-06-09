module Cms::RedirectPage
  extend ActiveSupport::Concern

  included do
    field :redirect_link, type: String
    permit_params :redirect_link

    before_validation :normalize_redirect_link, if: ->{ redirect_link.present? }
    validates :redirect_link, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
  end

  def view_layout
    redirect_link.present? ? "cms/redirect" : "cms/page"
  end

  private

  def normalize_redirect_link
    self.redirect_link = redirect_link.strip
    uri = ::Addressable::URI.parse(redirect_link)

    if uri.scheme.nil?
      self.redirect_link = ::File.join((@cur_site || site).root_url, redirect_link)
    end
  rescue => _e
    errors.add :redirect_link, :invalid
  end
end
