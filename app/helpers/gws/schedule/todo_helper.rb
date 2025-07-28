module Gws::Schedule::TodoHelper
  extend ActiveSupport::Concern
  include Gws::Schedule::PlanHelper

  def calendar_redirect_url
    return @calendar_redirect_url if instance_variable_defined?(:@calendar_redirect_url)

    @calendar_redirect_url = nil
    path = params.dig(:calendar, :path).to_s
    return if path.blank?
    return unless Sys::TrustedUrlValidator.myself_url?(path)

    uri = ::Addressable::URI.parse(path)
    @calendar_redirect_url = uri.request_uri
  end
end
