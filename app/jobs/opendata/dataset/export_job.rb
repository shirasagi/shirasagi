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
    data = @items.to_csv.encode("cp932", invalid: :replace, undef: :replace)
    write_csv("datasets", data)
  end

  def export_resources
    @items.each do |item|
      data = resources_to_csv(item.resources).encode("cp932", invalid: :replace, undef: :replace)
      write_resource_csv("resources", data, item.id)
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

  def write_csv(name, data)
    File.write("#{@output_dir}/#{name}.csv", data, encoding: "cp932")
  end

  def write_resource_csv(name, data, id)
    FileUtils.mkdir_p("#{@output_dir}/#{id}")
    File.write("#{@output_dir}/#{id}/#{name}.csv", data, encoding: "cp932")
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
        data << item.id
        data << item.name
        data << item.format
        data << item.license.try(:name)
        data << item.text
        data << item.file.try(:name)
        data << item.tsv.try(:name)
        data << csv_line(item)
      end
    end
  end
end
