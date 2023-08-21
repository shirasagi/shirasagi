module Job::Cms::CopyNodes::CmsLayouts
  extend ActiveSupport::Concern
  include SS::Copy::CmsLayouts
  include Job::Cms::CopyNodes::CmsContents

  def copy_cms_layouts
    Cms::Layout.site(@cur_site).excludes(depth: 1).where(filename: /^#{@cur_node.filename}\//).each do |layout|
      copy_cms_layout(layout)
    end
  end
end
