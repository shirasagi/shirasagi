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

  def export_datasets
    csv = @items.to_csv.encode("cp932", invalid: :replace, undef: :replace)
    path = "#{@output_dir}/datasets.csv"

    ::File.binwrite(path, csv)
  end

  def export_resources
    @items.each do |item|
      next if item.resources.blank?

      csv = resources_to_csv(item.resources).encode("cp932", invalid: :replace, undef: :replace)
      dir = "#{@output_dir}/#{item.id}"
      path = "#{dir}/resources.csv"

      ::FileUtils.mkdir_p(dir)
      ::File.binwrite(path, csv)

      item.resources.each do |resource|
        write_file(resource.file.name, resource.file.path, item.id, resource.id) if resource.file.present?
        write_file(resource.tsv.name, resource.tsv.path, item.id, resource.id) if resource.tsv.present?
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

  def write_file(name, path, dataset_id, resource_id)
    file = File.open(path, "r")
    data = file.read
    FileUtils.mkdir_p("#{@output_dir}/#{dataset_id}/#{resource_id}")
    File.write("#{@output_dir}/#{dataset_id}/#{resource_id}/#{name}", data)
    file.close
  end

  def resources_to_csv(resources)
    CSV.generate do |data|
      headers = %w(id name format license_id text file_id tsv_id).map { |k| Opendata::Resource.t(k) }

      data << headers
      resources.each do |item|
        line = []
        line << item.id
        line << item.name
        line << item.format
        line << item.license.try(:name)
        line << item.text
        line << item.file.try(:name)
        line << item.tsv.try(:name)
        data << line
      end
    end
  end
end
