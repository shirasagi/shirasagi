class Cms::CheckLinks::Report
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name 'cms_check_links', :use

  seqid :id
  field :name, type: String

  has_many :link_errors, foreign_key: "report_id", class_name: "Cms::CheckLinks::Error::Base",
    dependent: :destroy, inverse_of: :report

  before_save :set_name

  default_scope ->{ order_by(created: -1) }

  private

  def set_name
    self.name ||= "実行結果 #{created.strftime("%m/%d %H:%M")}"
  end

  public

  def name_with_site
    "[#{site.try(:name)}] #{name}"
  end

  def pages
    Cms::CheckLinks::Error::Page.and_report(self)
  end

  def nodes
    Cms::CheckLinks::Error::Node.and_report(self)
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
