module Recommend
  module_function

  mattr_accessor(:expire_logs_in, instance_accessor: false)
  self.expire_logs_in = 2.weeks

  def content(site, path)
    return if site.blank? || path.blank?

    filename = path.sub(/^#{::Regexp.escape(site.url)}/, "")
    page = Cms::Page.site(site).where(filename: filename).first
    return page if page

    filename = filename.sub(/\/index\.html$/, "")
    node = Cms::Node.site(site).where(filename: filename).first
    return node if node

    nil
  end
end
