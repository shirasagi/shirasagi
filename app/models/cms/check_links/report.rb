class Cms::CheckLinks::Report
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Cms::PublicFilter::Agent

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

  def save_error(ref, urls)
    return true if urls.blank?

    ref_url = File.join(site.full_root_url, ref) if ref[0] == "/"

    filename = ref.sub(/^#{::Regexp.escape(site.url)}/, "")
    filename.sub!(/\?.*$/, "")
    filename += "index.html" if ref.match?(/\/$/)

    page = find_page(filename)
    if page
      ref = ref.sub(/\/$/, "/index.html")
      cond = { site_id: site.id, report_id: self.id, ref: ref }
      item = Cms::CheckLinks::Error::Page.find_or_initialize_by(cond)
      item.ref_url = ref_url
      item.page = page
      item.name = page.name
      item.filename = page.filename
      item.urls = (item.urls.to_a + urls).uniq
      item.group_ids = (item.group_ids.to_a + page.group_ids.to_a).uniq
      return item.save
    end

    node = find_node(filename)
    if node
      ref = ref.sub(/\/index\.html$/, "/")
      cond = { site_id: site.id, report_id: self.id, ref: ref }
      item = Cms::CheckLinks::Error::Node.find_or_initialize_by(cond)
      item.ref_url = ref_url
      item.node = node
      item.name = node.name
      item.filename = node.filename
      item.urls = (item.urls.to_a + urls).uniq
      item.group_ids = (item.group_ids.to_a + node.group_ids.to_a).uniq
      return item.save
    end

    false
  end

  private

  def find_page(filename)
    Cms::Page.site(site).filename(filename).first
  end

  def find_node(filename)
    node = Cms::Node.site(site).in_path(filename).order_by(depth: -1).to_a.first
    return unless node

    rest = filename.delete_prefix(node.filename).sub(/\/index\.html$/, "")
    path = "/.s#{site.id}/nodes/#{node.route}#{rest}"

    spec = recognize_agent path
    return unless spec

    node
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
