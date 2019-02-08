class Opendata::Dataset::ExportJob < Cms::ApplicationJob
  def perform(opts = {})
    @items = Opendata::Dataset.site(site).node(node).allow(:read, user)

    @root_url = opts[:root_url].to_s
    @output_zip = SS::DownloadJobFile.new(user, "opendata-datasets-#{Time.zone.now.to_i}.zip")
    @output_dir = @output_zip.path.sub(::File.extname(@output_zip.path), "")

    FileUtils.rm_rf(@output_dir)
    FileUtils.rm_rf(@output_zip.path)
    FileUtils.mkdir_p(@output_dir)

    export_datasets
    export_resources

    zip = Opendata::Dataset::Export::Zip.new(@output_zip.path)
    zip.output_dir = @output_dir
    zip.compress

    FileUtils.rm_rf(@output_dir)

    create_notify_mail
  end

  def write_file(path, data)
    path = ::File.join(@output_dir, path)
    ::FileUtils.mkdir_p(::File.dirname(path))
    ::File.binwrite(path, data)
  end

  def export_datasets
    csv = @items.to_csv.encode("cp932", invalid: :replace, undef: :replace)
    path = "datasets.csv"
    write_file(path, csv)
  end

  def export_resources
    ids = @items.pluck(:id)
    ids.each do |id|
      item = Opendata::Dataset.find(id) rescue nil

      next if item.nil?
      next if item.resources.blank?

      csv = resources_to_csv(item.resources).encode("cp932", invalid: :replace, undef: :replace)
      path = "#{item.id}/resources.csv"
      write_file(path, csv)

      item.resources.each do |resource|
        if resource.file.present?
          path = "#{item.id}/#{resource.id}/#{resource.file.name}"
          write_file(path, resource.file.read)
        end

        if resource.tsv.present?
          path = "#{item.id}/#{resource.id}/#{resource.tsv.name}"
          write_file(path, resource.tsv.read)
        end
      end
    end
  end

  def resources_to_csv(resources)
    CSV.generate do |data|
      headers = %w(id name format license_id text file_id source_url tsv_id).map { |k| Opendata::Resource.t(k) }

      data << headers
      resources.each do |item|
        line = []
        line << item.id
        line << item.name
        line << item.format
        line << item.license.try(:name)
        line << item.text
        line << item.file.try(:name)
        line << item.source_url
        line << item.tsv.try(:name)
        data << line
      end
    end
  end

  def create_notify_mail
    args = {}
    args[:site] = site
    args[:t_uid] = user.id
    args[:link] = ::File.join(@root_url, @output_zip.url)
    Opendata::Mailer.export_datasets_mail(args).deliver_now rescue nil
  end
end
