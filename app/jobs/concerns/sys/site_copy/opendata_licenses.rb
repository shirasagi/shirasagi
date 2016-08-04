module Sys::SiteCopy::OpendataLicenses
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
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

  def copy_opendata_license(src_license)
    dest_content = nil
    id = cache(:opendata_licenses, src_license.id) do
      dest_content = Opendata::License.new(cur_site: @dest_site)
      dest_content.attributes = copy_basic_attributes(src_license, Opendata::License)
      dest_content.attributes.merge(resolve_unsafe_references(src_license, Opendata::License))
      dest_content.save!
      dest_content.id
    end

    dest_content ||= Opendata::DatasetGroup.site(@dest_site).find(id) if id
    dest_content
  rescue => e
    @task.log("#{src_page.filename}(#{src_page.id}): ライセンスのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
