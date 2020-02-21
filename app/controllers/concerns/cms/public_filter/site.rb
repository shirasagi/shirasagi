module Cms::PublicFilter::Site
  extend ActiveSupport::Concern

  included do
    before_action :set_site
  end

  private

  def set_site
    @cur_site ||= request.env["ss.site"] ||= SS::Site.find_by_domain(request_host, request_path)
  end
end
