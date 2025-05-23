module Sys::SiteCopy::CmsFiles
  extend ActiveSupport::Concern
  include SS::Copy::Cache
  include Sys::SiteCopy::SSFiles

  def copy_cms_files
    file_ids = Cms::File.site(@src_site).where(model: Cms::File::FILE_MODEL).pluck(:id)
    file_ids.each do |file_id|
      file = Cms::File.site(@src_site).find(file_id) rescue nil
      next if file.blank?
      copy_ss_file(file)
    end
  end
end
