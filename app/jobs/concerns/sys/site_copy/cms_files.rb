module Sys::SiteCopy::CmsFiles
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::SsFiles

  def copy_cms_files
    Cms::File.site(@src_site).where(model: "cms/file").each do |file|
      copy_ss_file(file)
    end
  end
end
