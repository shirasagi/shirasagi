module Sys::SiteCopy::CmsFiles
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::SsFiles

  def copy_cms_files
    file_ids = Cms::File.site(@src_site).where(model: "cms/file").pluck(:id)
    file_ids.each do |file_id|
      file = Cms::File.site(@src_site).find(file_id) rescue nil
      next if file.blank?
      copy_ss_file(file)
    end
  end
end
