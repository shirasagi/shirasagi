require "csv"

class Opendata::Dataset::ImportJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(ss_file_id)
    file = ::SS::File.find(ss_file_id)

    @import_dir = "#{Rails.root}/private/import/opendata-datasets-#{Time.zone.now.to_i}"

    FileUtils.rm_rf(@import_dir)
    FileUtils.mkdir_p(@import_dir)

    Zip::File.open(file.path) do |entries|
      entries.each do |entry|
        path = "#{@import_dir}/" + entry.name.encode("utf-8", "cp932", invalid: :replace, undef: :replace).tr('\\', '/')

        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          File.binwrite(path, entry.get_input_stream.read)
        end
      end
    end

    dataset_csv = Dir.glob("#{@import_dir}/datasets.csv").first
    dataset_csv ||= Dir.glob("#{@import_dir}/*/datasets.csv").first

    if dataset_csv
      put_log("import start #{dataset_csv}")
      import_dataset_csv(dataset_csv)
    else
      put_log("not found datasets.csv")
    end

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
        put_log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
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
        put_log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end

  def update_dataset_row(row)
    @dataset_id = value(row, :id).to_i
    item = model.where(site_id: site.id, id: @dataset_id).first || model.new
    item.cur_site = site
    item.cur_node = node

    set_dataset_attributes(row, item)

    if item.valid?
      item.save
      resources_csv = Dir.glob("#{@import_dir}/#{@dataset_id}/resources.csv").first
      resources_csv ||= Dir.glob("#{@import_dir}/*/#{@dataset_id}/resources.csv").first

      if resources_csv
        put_log("import start #{resources_csv}")
        import_resource_csv(resources_csv, item)
      else
        put_log("not found resources.csv (#{item.name})")
      end
      item
    else
      raise item.errors.full_messages.join(", ")
    end
  end

  def update_resource_row(dataset, row)
    id = resource_value(row, :id).to_i
    item = dataset.resources.detect { |resource| resource.id == id }
    item = dataset.resources.new if item.blank?
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

  def category_name_tree_to_ids(name_trees, klass)
    names = name_trees.map { |name| name.split(/\//).last }
    klass.site(site).in(name: names).pluck(:id)
  end

  def set_dataset_attributes(row, item)
    # basic
    item.name = value(row, :name)
    item.text = value(row, :text)
    item.tags = value(row, :tags).to_s.split(",")

    # category
    category_name_tree = ary_value(row, :category_ids)
    item.category_ids = category_name_tree_to_ids(category_name_tree, Opendata::Node::Category)

    # estat_category
    estat_category_name_tree = ary_value(row, :estat_category_ids)
    item.estat_category_ids = category_name_tree_to_ids(estat_category_name_tree, Opendata::Node::EstatCategory)

    # area
    item.area_ids = Opendata::Node::Area.in(name: ary_value(row, :area_ids)).pluck(:id).uniq

    # dataset_group
    dataset_group_names = ary_value(row, :dataset_group_ids)
    item.dataset_group_ids = Opendata::DatasetGroup.in(name: dataset_group_names).pluck(:id).uniq

    # released
    released = value(row, :released)
    item.released = Time.zone.strptime(released, "%Y/%m/%d %H:%M") if released.present?

    # contact
    item.contact_state = value(row, :contact_state)
    item.contact_group_id = SS::Group.where(name: value(row, :contact_group_id)).first.try(:id)
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
    group_names = ary_value(row, :groups)
    item.group_ids = SS::Group.in(name: group_names).pluck(:id)
  end

  def set_resource_attributes(row, dataset, item)
    license = Opendata::License.where(name: resource_value(row, :license_id)).first

    item.name = resource_value(row, :name)
    item.format = resource_value(row, :format)
    item.license_id = license.id if license
    item.text = resource_value(row, :text)
    item.order = resource_value(row, :order).to_i
    if resource_value(row, :file_id).present?
      path1 = "#{@import_dir}/#{@dataset_id}/#{resource_value(row, :id)}/#{resource_value(row, :file_id)}"
      path2 = "#{@import_dir}/*/#{@dataset_id}/#{resource_value(row, :id)}/#{resource_value(row, :file_id)}"

      file_path = Dir.glob(path1).first
      file_path ||= Dir.glob(path2).first
      raise "not_found file_path #{path1}" if file_path.blank?

      file = SS::File.new(model: "opendata/resource", state: "public")
      file.in_file = Fs::UploadedFile.create_from_file(File.open(file_path, "r"))
      file.save!
      item.filename = file.name
      item.file_id = file.id
    end
    if resource_value(row, :tsv_id).present?
      tsv_path1 = "#{@import_dir}/#{@dataset_id}/#{resource_value(row, :id)}/#{resource_value(row, :tsv_id)}"
      tsv_path2 = "#{@import_dir}/*/#{@dataset_id}/#{resource_value(row, :id)}/#{resource_value(row, :tsv_id)}"

      tsv_file_path = Dir.glob(tsv_path1).first
      tsv_file_path ||= Dir.glob(tsv_path2).first

      tsv = SS::File.new(model: "opendata/resource", state: "public")
      tsv.in_file = Fs::UploadedFile.create_from_file(File.open(tsv_file_path, "r"))
      tsv.save!
      item.tsv_id = tsv.id
    end
  end
end
