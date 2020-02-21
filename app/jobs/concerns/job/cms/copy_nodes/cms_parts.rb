module Job::Cms::CopyNodes::CmsParts
  extend ActiveSupport::Concern
  include SS::Copy::CmsParts
  include Job::Cms::CopyNodes::CmsContents

  def copy_cms_parts
    Cms::Part.site(@cur_site).where(filename: /^#{@cur_node.filename}\//).each do |part|
      copy_cms_part(part)
    end
  end
end
