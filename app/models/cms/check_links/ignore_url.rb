class Cms::CheckLinks::IgnoreUrl
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_check_links_ignore_urls", :edit

  seqid :id
  field :name, type: String
  field :kind, type: String, default: "all"
  permit_params :name, :kind

  validates :name, presence: true

  def kind_options
    I18n.t("cms.options.ignore_url_kind").map { |k, v| [v, k] }
  end

  def match?(full_url)
    return false if full_url.blank?

    case kind
    when "start_with"
      full_url.origin.start_with?(name) || full_url.request_uri.start_with?(name) || full_url.to_s.start_with?(name)
    when "end_with"
      full_url.origin.end_with?(name) || full_url.path.end_with?(name) || full_url.request_uri.end_with?(name) || full_url.to_s.end_with?(name)
    when "include"
      full_url.to_s.include?(name)
    else
      full_url == Addressable::URI.join(site.full_url, name)
    end
  end

  class << self
    def search(params = {})
      criteria = all
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in(params[:keyword], :name)
      end

      criteria
    end
  end
end
