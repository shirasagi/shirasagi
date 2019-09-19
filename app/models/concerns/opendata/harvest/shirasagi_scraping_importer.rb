module Opendata::Harvest::ShirasagiScrapingImporter
  extend ActiveSupport::Concern

  private

  def import_from_shirasagi_scraper
    put_log("import from #{source_url} (SHIRASAGI scraper)")

    if reports.count >= 5
      reports.order_by(created: 1).first.destroy
    end

    @report = Opendata::Harvest::Importer::Report.new(cur_site: site, importer: self)
    @report.save!

    package = ::Opendata::Harvest::ShirasagiScraper.new(source_url)

    urls = package.get_dataset_urls
    put_log("dataset_urls #{urls.size}")

    imported_dataset_ids = []
    urls.each_with_index do |url, idx|
      begin
        put_log("- #{idx + 1} #{url}")

        @report_dataset = @report.new_dataset

        dataset_attributes = package.get_dataset(url)
        dataset = create_dataset_from_shirasagi_scraper(dataset_attributes)

        @report_dataset.set_reports(dataset, dataset_attributes, url, idx)

        imported_dataset_ids << dataset.id

        license = get_license_from_name(dataset_attributes["license_title"])

        imported_resource_ids = []
        dataset_attributes["resources"].each_with_index do |resource_attributes, idx|
          begin
            @report_resource = @report_dataset.new_resource

            resource = create_resource_from_shirasagi_scraper(resource_attributes, idx, dataset, license)
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
        dataset.save!
        set_relation_ids(dataset)

        @report_dataset.set_reports(dataset, dataset_attributes, url, idx)
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

  def create_dataset_from_shirasagi_scraper(attributes)
    dataset = ::Opendata::Dataset.node(node).where(harvest_imported_url: attributes["url"]).first
    dataset ||= ::Opendata::Dataset.new

    dataset.cur_site = site
    dataset.cur_node = node
    def dataset.set_updated; end

    dataset.layout = node.page_layout || node.layout
    #dataset.uuid = attributes["uuid"]
    dataset.name = attributes["name"]
    dataset.text = attributes["text"]
    dataset.update_plan = attributes["update_plan"]
    dataset.contact_charge = attributes["author"] if attributes["author"].present?
    dataset.group_ids = group_ids

    dataset.updated = attributes["updated"] || Time.zone.now
    dataset.created = dataset.updated
    dataset.released = dataset.updated

    dataset.harvest_importer = self
    dataset.harvest_host = source_host
    dataset.harvest_api_type = api_type

    #dataset.harvest_imported ||= Time.zone.now
    dataset.harvest_imported_url = attributes["url"]
    dataset.harvest_imported_attributes = attributes
    dataset.harvest_source_url = attributes["url"]
    dataset.state = "public"

    put_log("- dataset : #{dataset.new_record? ? "create" : "update"} #{dataset.name}")

    dataset.save!

    dataset
  end

  def create_resource_from_shirasagi_scraper(attributes, idx, dataset, license)
    resource = dataset.resources.select { |r| r.harvest_imported_url == attributes["url"] }.first

    if resource
      put_log("-- same url resource exists #{attributes["url"]}")
    else
      resource = Opendata::Resource.new
      dataset.resources << resource
    end

    url = attributes["url"]
    filename = attributes["filename"]
    format = attributes["format"].downcase

    if external_resouce?(url, format)
      # set source url
      resource.source_url = url
      format = "html"
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
      ss_file.save!

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
    #resource.uuid = attributes["uuid"]
    #resource.revision_id = attributes["revision_id"]
    resource.name = attributes["name"]
    resource.text = attributes["text"]
    resource.filename = filename
    resource.format = format
    resource.license = license

    def resource.set_updated; end

    def resource.compression_dataset; end

    resource.created = dataset.created
    resource.updated = dataset.updated

    resource.file_id = ss_file.id

    resource.harvest_importer = self
    resource.harvest_host = source_host
    resource.harvest_api_type = api_type

    resource.harvest_imported ||= Time.zone.now
    resource.harvest_imported_url = url
    resource.harvest_imported_attributes = attributes

    if resource.new_record?
      put_log("-- resource : create #{resource.name}")
    else
      put_log("-- resource : update #{resource.name}")
    end

    resource.save!
    resource
  end
end
