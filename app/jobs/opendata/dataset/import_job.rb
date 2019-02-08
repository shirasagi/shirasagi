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
        path = "#{@import_dir}/" + entry.name.encode("utf-8", "cp932", invalid: :replace, undef: :replace).tr('\\', '/')

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
    item = model.find_or_initialize_by(site_id: site.id, id: value(row, :id).to_i)
    set_dataset_attributes(row, item)
    item.cur_node = node

    if item.valid?
      item.save
      resources_csv = Dir.glob("#{@import_dir}/#{value(row, :id)}/*.csv").first || Dir.glob("#{@import_dir}/*/#{value(row, :id)}/*.csv").first

      put_log("import start #{resources_csv}")
      import_resource_csv(resources_csv, item)
      item
    else
      raise item.errors.full_messages.join(", ")
    end
  end

  def update_resource_row(dataset, row)
    item = dataset.resources.detect {|resource| resource.id == resource_value(row, :id).to_i}
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
    category_ids = []
    name_trees.each do |cate|
      ct_list = []
      ct = klass.site(site).where(name: cate).first
      ct_list << ct if ct

      if ct_list.present?
        ct = ct_list.last
        category_ids << ct.id
      end
    end
    category_ids
  end

  def set_dataset_attributes(row, item)
    # basic
    item.name = value(row, :name)
    item.text = value(row, :text)
    item.tags = value(row, :tags).to_s.split(",")

    # category
    category_name_tree = ary_value(row, :categories)
    category_ids = category_name_tree_to_ids(category_name_tree, Opendata::Node::Category)
    categories = Opendata::Node::Category.site(site).in(id: category_ids)
    item.category_ids = categories.pluck(:id)

    # estat_category
    estat_category_name_tree = ary_value(row, :estat_categories)
    estat_category_ids = category_name_tree_to_ids(estat_category_name_tree, Opendata::Node::EstatCategory)
    estat_categories = Opendata::Node::EstatCategory.site(site).in(id: estat_category_ids)
    item.estat_category_ids = estat_categories.pluck(:id)

    # area
    item.area_ids = Opendata::Node::Area.in(name: ary_value(row, :area_ids)).pluck(:id)

    # dataset_group
    dataset_group_names = ary_value(row, :dataset_group_ids)
    item.dataset_group_ids = Opendata::DatasetGroup.in(name: dataset_group_names).pluck(:id)

    # released
    item.released = Time.zone.strptime(value(row, :released), "%Y/%m/%d %H:%M")

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
    item.name = resource_value(row, :name)
    item.format = resource_value(row, :format)
    item.license_id = Opendata::License.find_by(name: resource_value(row, :license_id)).try(:id)
    item.text = resource_value(row, :text)
    if resource_value(row, :file_id).present?
      path1 = "#{@import_dir}/#{dataset.id}/#{resource_value(row, :id)}/#{resource_value(row, :file_id)}"
      path2 = "#{@import_dir}/*/#{dataset.id}/#{resource_value(row, :id)}/#{resource_value(row, :file_id)}"

      file_path = Dir.glob(path1).first
      file_path ||= Dir.glob(path2).first
      raise "not_found file_path #{path1}" if file_path.blank?

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
