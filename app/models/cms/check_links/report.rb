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

  def save_errors(errors)
    error_full_urs = Set.new
    errors.each { error_full_urs.add(_1.full_url) }

    referrers = errors.map(&:referrers)
    referrers.flatten!
    referrers.uniq!
    map = referrers.group_by { _1.full_url }

    # 例えば "/" と "/index.html" は同じページを指している場合がある。
    # URL で名寄せした後、ページ・フォルダーで再び名寄せする
    page_map = {}
    node_map = {}
    map.each do |full_url, sources|
      filename = full_url.path.sub(/^#{::Regexp.escape(site.url)}/, "")
      filename += "index.html" if filename.end_with?("/")

      page = find_page(filename)
      if page
        page_map[page] ||= []
        page_map[page] += sources
        next
      end

      node = find_node(filename)
      next unless node

      node_map[node] ||= []
      node_map[node] += sources
    end

    page_map.each do |page, sources|
      item = Cms::CheckLinks::Error::Page.new(site_id: site.id, report_id: self.id)
      item.ref = page.url
      item.ref_url = page.full_url
      item.page = page
      item.name = page.name
      item.filename = page.filename

      links = sources.map(&:links)
      links.flatten!

      error_links = links.select { error_full_urs.include?(_1.full_url) }
      item.urls = (item.urls.to_a + error_links.map { _1.href }).uniq
      item.group_ids = (item.group_ids.to_a + page.group_ids.to_a).uniq
      item.save
    end

    node_map.each do |node, referrers|
      item = Cms::CheckLinks::Error::Node.new(site_id: site.id, report_id: self.id)
      item.ref = node.url
      item.ref_url = node.full_url
      item.node = node
      item.name = node.name
      item.filename = node.filename

      links = sources.map(&:links)
      links.flatten!

      error_links = links.select { error_full_urs.include?(_1.full_url) }
      item.urls = (item.urls.to_a + error_links.map { _1.href }).uniq
      item.group_ids = (item.group_ids.to_a + node.group_ids.to_a).uniq
      item.save
    end
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
