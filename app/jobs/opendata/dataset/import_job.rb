require "csv"

class Opendata::Dataset::ImportJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(ss_file_id)
    file = ::SS::File.find(ss_file_id) rescue nil

    @datetime = Time.zone.now
    @import_dir = "#{Rails.root}/private/import/opendata-datasets-#{@datetime.strftime('%Y%m%d%H%M%S')}"

    FileUtils.rm_rf(@import_dir)
    FileUtils.mkdir_p(@import_dir)

    Zip::File.open(file.path) do |entries|
      entries.each do |entry|
        path = "#{@import_dir}/" + entry.name.encode("utf-8", "cp932").tr('\\', '/')

        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          File.binwrite(path, entry.get_input_stream.read)
        end
      end
    end

    dataset_csv = Dir.glob("#{@import_dir}/*.csv").first || Dir.glob("#{@import_dir}/*/*.csv").first

    put_log("import start #{dataset_csv}")
    import_dataset_csv(dataset_csv)

    FileUtils.rm_rf(@import_dir)
  end

  def model
    Opendata::Dataset
  end

  def import_dataset_csv(file)
    table = CSV.read(file, headers: true, encoding: 'SJIS:UTF-8')
    table.each.with_index(1) do |row, i|
      begin
        item = update_dataset_row(row)
        put_log("update #{i}: #{item.name}")
      rescue => e
        put_log("error  #{i}: #{e}")
      end
    end
  end

  def import_resource_csv(file, dataset)
    table = CSV.read(file, headers: true, encoding: 'SJIS:UTF-8')
    table.each.with_index(1) do |row, i|
      begin
        item = update_resource_row(dataset, row)
        put_log("update #{i}: #{item.try(:name)}")
      rescue => e
        put_log("error  #{i}: #{e}")
      end
    end
  end

  def update_dataset_row(row)
    item = model.find_or_initialize_by(site_id: site.id, id: value(row, :id).to_i)
    set_dataset_attributes(row, item)

    if item.save
      resources_csv = Dir.glob("#{@import_dir}/#{item.id}/*.csv").first || Dir.glob("#{@import_dir}/*/#{item.id}/*.csv").first

      put_log("import start #{resources_csv}")
      import_resource_csv(resources_csv, item)
      item
    else
      raise item.errors.full_messages.join(", ")
    end
  end

  def update_resource_row(dataset, row)
    item = dataset.resources.detect {|resource| resource.id == resource_value(row, :id).to_i}
    return if item.blank?
    set_resource_attributes(row, dataset, item)

    if item.save
      item
    else
      raise item.errors.full_messages.join(", ")
    end
  end

  def value(row, key)
    row[model.t(key)].try(:strip)
  end

  def ary_value(row, key)
    row[model.t(key)].to_s.split(/\n/).map(&:strip)
  end

  def resource_value(row, key)
    row[Opendata::Resource.t(key)].try(:strip)
  end

  def set_dataset_attributes(row, item)
    # basic
    item.name = value(row, :name)
    item.text = value(row, :text)
    item.tags = value(row, :tags).split(",")

    # category area
    item.category_ids = value(row, :categories).split(",")
    item.area_ids = value(row, :area_ids).split(",")

    # dataset_group
    item.dataset_group_ids = value(row, :dataset_group_ids).split(",")

    # released
    item.released = Time.zone.strptime(value(row, :released), "%Y/%m/%d %H:%M")

    # contact
    item.contact_state = value(row, :contact_state)
    item.contact_group_id = value(row, :contact_group)
    item.contact_charge = value(row, :contact_charge)
    item.contact_tel = value(row, :contact_tel)
    item.contact_fax = value(row, :contact_fax)
    item.contact_email = value(row, :contact_email)
    item.contact_link_url = value(row, :contact_link_url)
    item.contact_link_name = value(row, :contact_link_name)

    # related pages
    page_names = ary_value(row, :related_pages)
    item.related_page_ids = Cms::Page.site(site).in(filename: page_names).pluck(:id)

    # groups
    item.group_ids = value(row, :groups).split(",")
  end

  def set_resource_attributes(row, dataset, item)
    item.name = resource_value(row, :name)
    item.format = resource_value(row, :format)
    item.license_id = resource_value(row, :license_id)
    item.text = resource_value(row, :text)
    if resource_value(row, :file_id).present?
      file_path = Dir.glob("#{@import_dir}/#{dataset.id}/#{item.id}/#{resource_value(row, :file_id)}").first || Dir.glob("#{@import_dir}/*/#{dataset.id}/#{item.id}/#{resource_value(row, :file_id)}").first
      file = SS::File.new(model: "opendata/resource", state: "public")
      file.in_file = Fs::UploadedFile.create_from_file(File.open(file_path, "r"))
      file.save
      item.filename = file.name
      item.file_id = file.id
    end
    if resource_value(row, :tsv_id).present?
      tsv_path = Dir.glob("#{@import_dir}/#{dataset.id}/#{item.id}/#{resource_value(row, :tsv_id)}").first || Dir.glob("#{@import_dir}/*/#{dataset.id}/#{item.id}/#{resource_value(row, :tsv_id)}").first
      tsv = SS::File.new(model: "opendata/resource", state: "public")
      tsv.in_file = Fs::UploadedFile.create_from_file(File.open(tsv_path, "r"))
      tsv.save
      item.tsv_id = tsv.id
    end
  end
end
