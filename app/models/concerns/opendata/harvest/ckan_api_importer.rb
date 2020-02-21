module Opendata::Harvest::CkanApiImporter
  extend ActiveSupport::Concern

  private

  def import_from_ckan_api
    put_log("import from #{source_url} (Ckan API)")

    if reports.count >= 5
      reports.order_by(created: 1).first.destroy
    end

    @report = Opendata::Harvest::Importer::Report.new(cur_site: site, importer: self)
    @report.save!

    package = ::Opendata::Harvest::CkanPackage.new(source_url)

    imported_dataset_ids = []
    list = package.package_list
    put_log("package_list #{list.size}")

    list.each_with_index do |name, idx|
      begin
        put_log("- #{idx + 1} #{name}")

        @report_dataset = @report.new_dataset

        dataset_attributes = package.package_show(name)
        dataset = create_dataset_from_ckan_api(
          dataset_attributes,
          package.package_show_url(name),
          package.dataset_url(name)
        )

        @report_dataset.set_reports(dataset, dataset_attributes, package.package_show_url(name), idx)

        imported_dataset_ids << dataset.id

        license_id = dataset_attributes["license_id"].to_s.downcase # uppercase? lowercase? license "id" is ambiguous
        license = get_license_from_uid(license_id)
        put_log("could not found license #{dataset_attributes["license_id"]}") if license.nil?

        # resources
        imported_resource_ids = []
        dataset_attributes["resources"].each_with_index do |resource_attributes, idx|
          begin
            @report_resource = @report_dataset.new_resource

            resource = create_resource_from_ckan_api(resource_attributes, idx, dataset, license)
            imported_resource_ids << resource.id

            @report_resource.set_reports(resource, resource_attributes, idx)
          rescue => e
            message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
            put_log(message)

            @report_resource.add_error(message)
          ensure
            @report_resource.save!
          end
        end

        # destroy unimported resources
        dataset.resources.each do |resource|
          next if imported_resource_ids.include?(resource.id)
          put_log("-- resource : destroy #{resource.name}")
          resource.destroy
        end

        dataset.harvest_imported ||= Time.zone.now
        set_relation_ids(dataset)

        @report_dataset.set_reports(dataset, dataset_attributes, package.package_show_url(name), idx)
      rescue => e
        message = "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
        put_log(message)

        @report_dataset.add_error(message)
      ensure
        @report_dataset.save!
      end
    end

    # destroy unimported datasets
    dataset_ids = ::Opendata::Dataset.site(site).node(node).where(
      "harvest_api_type" => api_type,
      "harvest_host" => source_host
    ).pluck(:id)
    dataset_ids -= imported_dataset_ids
    dataset_ids.each do |id|
      dataset = ::Opendata::Dataset.find(id) rescue nil
      next unless dataset

      put_log("- dataset : destroy #{dataset.name}")
      dataset.destroy
    end

    @report.save!
  end

  def create_dataset_from_ckan_api(attributes, url, dataset_url)
    dataset = ::Opendata::Dataset.node(node).where(uuid: attributes["id"]).first
    dataset ||= ::Opendata::Dataset.new

    dataset.cur_site = site
    dataset.cur_node = node
    def dataset.set_updated; end

    dataset.layout = node.page_layout || node.layout
    dataset.uuid = attributes["id"]
    dataset.name = attributes["title"]
    dataset.text = attributes["notes"]
    dataset.contact_charge = attributes["author"] if attributes["author"].present?
    dataset.group_ids = group_ids

    dataset.created = Time.zone.parse(attributes["metadata_created"]) || Time.zone.now
    dataset.updated = Time.zone.parse(attributes["metadata_modified"]) || dataset.created
    dataset.released = dataset.created

    dataset.harvest_importer = self
    dataset.harvest_host = source_host
    dataset.harvest_api_type = api_type

    #dataset.harvest_imported ||= Time.zone.now
    dataset.harvest_imported_url = url
    dataset.harvest_imported_attributes = attributes
    dataset.harvest_source_url = dataset_url
    dataset.state = "public"

    put_log("- dataset : #{dataset.new_record? ? "create" : "update"} #{dataset.name}")
    dataset.save!

    dataset
  end

  def create_resource_from_ckan_api(attributes, idx, dataset, license)
    resource = dataset.resources.select { |r| r.uuid == attributes["id"] }.first

    if resource.nil?
      resource = Opendata::Resource.new
      dataset.resources << resource
    end

    if resource.revision_id == attributes["revision_id"]
      put_log("-- resource : same revision_id #{resource.name}")
      return resource
    end

    url = attributes["url"]
    filename = attributes["name"] + ::File.extname(url)
    format = attributes["format"]
    format = ::File.extname(url).delete(".").sub(/\?.*$/, "").downcase if format.blank?
    format = "html" if format.blank?

    if external_resouce?(url, format)
      # set source url
      resource.source_url = url
    else
      # download file from url
      if resource.file
        ss_file = SS::StreamingFile.find(resource.file_id)
        ss_file.name = nil
        ss_file.filename = nil
      else
        ss_file = SS::StreamingFile.new
        ss_file.in_size_limit = resource_size_limit_mb * 1024 * 1024
      end
      ss_file.in_remote_url = url
      ss_file.model = "opendata/resource"
      ss_file.state = "public"
      ss_file.site_id = site.id

      begin
        ss_file.save!
        resource.file_id = ss_file.id
      rescue SS::StreamingFile::SizeError => e
        # set source url
        resource.source_url = url
        put_log("-- #{filename} : file size exceeded #{resource_size_limit_mb} MB, set source_url")
      end
    end

    resource.order = idx
    resource.uuid = attributes["id"]
    resource.revision_id = attributes["revision_id"]
    resource.name = attributes["name"]
    resource.text = attributes["description"]
    resource.filename = filename
    resource.format = format
    resource.license = license

    def resource.set_updated; end

    def resource.set_revision_id; end

    def resource.compression_dataset; end

    resource.updated = dataset.updated
    resource.created = dataset.created

    resource.harvest_importer = self
    resource.harvest_host = source_host
    resource.harvest_api_type = api_type

    resource.harvest_imported ||= Time.zone.now
    resource.harvest_imported_url = url
    resource.harvest_imported_attributes = attributes

    put_log("-- resource : #{resource.new_record? ? "create" : "update"} #{resource.name}")

    resource.save!
    resource
  end
end
