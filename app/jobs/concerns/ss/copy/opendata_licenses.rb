module SS::Copy::OpendataLicenses
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def resolve_opendata_license_reference(id)
    id
  end

  def copy_opendata_license(src_license)
    # at first, it is required to resolve file reference
    unsafe_attrs = resolve_unsafe_references(src_license, Opendata::License)

    dest_content = nil
    id = cache(:opendata_licenses, src_license.id) do
      dest_content = Opendata::License.site(@dest_site).where(name: src_license.name).first
      return dest_content if dest_content.present?

      dest_content = Opendata::License.new(cur_site: @dest_site)
      dest_content.attributes = copy_basic_attributes(src_license, Opendata::License).merge(unsafe_attrs)
      dest_content.save!
      dest_content.id
    end

    dest_content ||= Opendata::License.site(@dest_site).find(id) if id
    dest_content
  rescue => e
    @task.log("#{src_license.name}(#{src_license.id}): ライセンスのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
