module Job::Cms::CopyNodes::CmsPages
  extend ActiveSupport::Concern
  include SS::Copy::CmsPages
  include Job::Cms::CopyNodes::CmsContents

  def copy_cms_pages
    Cms::Page.site(@cur_site).where(filename: /^#{@cur_node.filename}\//).each do |page|
      copy_cms_page(page)
    end
  end
end
