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
