module Sys::SiteCopy::OpendataLicenses
  extend ActiveSupport::Concern
  include SS::Copy::OpendataLicenses
  include Sys::SiteCopy::CmsContents

  def resolve_opendata_license_reference(id)
    cache(:opendata_licenses, id) do
      src_license = Opendata::License.site(@src_site).find(id) rescue nil
      if src_license.blank?
        Rails.logger.warn("#{id}: 参照されているライセンスが存在しません。")
        return nil
      end

      dest_license = copy_opendata_license(src_license)
      dest_license.try(:id)
    end
  end
end
