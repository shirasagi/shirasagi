class Opendata::Dataset::ImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "opendata:import_datasets"

  def perform(ss_file_id)
    file = SS::File.find(ss_file_id)
    put_log("import start " + ::File.basename(file.name))
    import_zip(file)
  ensure
    file.destroy rescue nil
    FileUtils.rm_rf(import_dir) rescue nil
  end

  private

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site.id
    cond[:node_id] = node.id
    cond
  end

  def put_log(message)
    if task
      task.log(message)
    else
      Rails.logger.info(message)
    end
  end

  def import_dir
    @import_dir ||= "#{Rails.root}/private/import/opendata-datasets-#{Time.zone.now.to_i}"
  end

  def import_dir_with_slash
    @import_dir_with_slash ||= "#{import_dir}/"
  end

  def prepare_import_dir
    FileUtils.rm_rf(import_dir)
    FileUtils.mkdir_p(import_dir)
  end

  def format_log_path(path)
    path.sub(import_dir_with_slash, "")
  end

  def import_zip(file)
    prepare_import_dir

    Zip::File.open(file.path) do |entries|
      entries.each do |entry|
        name = entry.name.encode("utf-8", "cp932", invalid: :replace, undef: :replace).tr('\\', '/')
        path = ::File.expand_path(name, import_dir)
        next unless path.start_with?(import_dir_with_slash)

        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          File.binwrite(path, entry.get_input_stream.read)
        end
      end
    end

    dataset_csv = Dir.glob("#{import_dir}/datasets.csv").first
    dataset_csv ||= Dir.glob("#{import_dir}/*/datasets.csv").first

    if dataset_csv
      put_log("import csv #{format_log_path(dataset_csv)}")
      @datasets_dir = ::File.dirname(dataset_csv)
      import_dataset_csv(dataset_csv)
    else
      put_log("not found datasets.csv")
    end
  end

  def import_dataset_csv(file)
    SS::Csv.foreach_row(file, headers: true) do |row, i|
      i += 1
      begin
        @dataset_index = i
        create_dataset(row)
      rescue => e
        put_log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end

  def import_resource_csv(file, dataset)
    SS::Csv.foreach_row(file, headers: true) do |row, i|
      i += 1
      begin
        @resource_index = i
        create_resource(dataset, row)
      rescue => e
        put_log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end

  def create_dataset(row)
    @dataset_id = value(row, Opendata::Dataset, :id).to_i
    if @dataset_id <= 0
      put_log("- dataset.#{@dataset_index} : not found dataset id")
      return
    end

    item = initialize_dataset(row)
    if item.save
      put_log("- dataset.#{@dataset_index} : saved #{item.name}(#{item.id})")

      resources_csv = Dir.glob("#{@datasets_dir}/#{@dataset_id}/resources.csv").first
      if resources_csv
        put_log("- dataset.#{@dataset_index} : import csv #{format_log_path(resources_csv)}")
        import_resource_csv(resources_csv, item)
      end
    else
      put_log("- dataset.#{@dataset_index} : save failed #{item.name} #{item.errors.full_messages.join(", ")}")
    end
  end

  def create_resource(dataset, row)
    @resource_id = value(row, Opendata::Resource, :id).to_i
    if @resource_id <= 0
      put_log("-- resource.#{@resource_index} : not found resource id")
      return nil
    end

    item = initialize_resource(row, dataset)
    if item.save
      put_log("-- resource.#{@resource_index} : saved #{item.name}(#{item.id})")
      item
    else
      put_log("-- resource.#{@resource_index} : save failed #{item.name} #{item.errors.full_messages.join(", ")}")
      nil
    end

    # reload dataset.resources.new
    # illegal records are created if not reload and save validation failed
    dataset.reload
  end

  def value(row, item, key)
    row[item.t(key)].try(:strip)
  end

  def array_value(row, item, key)
    row[item.t(key)].to_s.split(/\R/).map(&:strip)
  end

  def category_name_tree_to_ids(name_trees, klass)
    names = name_trees.map { |name| name.split("/").last }
    klass.site(site).in(name: names).pluck(:id)
  end

  def initialize_dataset(row)
    item = Opendata::Dataset.new
    item.cur_site = site
    item.cur_node = node

    # basic
    item.name = value(row, item, :name)
    item.text = value(row, item, :text)
    item.tags = array_value(row, item, :tags)

    # category
    category_name_tree = array_value(row, item, :category_ids)
    item.category_ids = category_name_tree_to_ids(category_name_tree, Opendata::Node::Category)

    # estat_category
    estat_category_name_tree = array_value(row, item, :estat_category_ids)
    item.estat_category_ids = category_name_tree_to_ids(estat_category_name_tree, Opendata::Node::EstatCategory)

    # area
    item.area_ids = Opendata::Node::Area.in(name: array_value(row, item, :area_ids)).pluck(:id).uniq

    # dataset_group
    dataset_group_names = array_value(row, item, :dataset_group_ids)
    item.dataset_group_ids = Opendata::DatasetGroup.in(name: dataset_group_names).pluck(:id).uniq

    # released
    released = value(row, item, :released)
    item.released = released.in_time_zone if released.present?

    # contact
    item.contact_state = value(row, item, :contact_state)
    item.contact_group_id = SS::Group.where(name: value(row, item, :contact_group_id)).first.try(:id)
    item.contact_charge = value(row, item, :contact_charge)
    item.contact_tel = value(row, item, :contact_tel)
    item.contact_fax = value(row, item, :contact_fax)
    item.contact_email = value(row, item, :contact_email)
    item.contact_link_url = value(row, item, :contact_link_url)
    item.contact_link_name = value(row, item, :contact_link_name)

    # related pages
    page_names = array_value(row, item, :related_pages)
    item.related_page_ids = Cms::Page.site(site).in(filename: page_names).pluck(:id)

    # groups
    group_names = array_value(row, item, :groups)
    item.group_ids = SS::Group.in(name: group_names).pluck(:id)

    item
  end

  def initialize_resource(row, dataset)
    item = dataset.resources.new

    license = Opendata::License.where(name: value(row, item, :license_id)).first
    file_name = value(row, item, :file_id)
    tsv_name = value(row, item, :tsv_id)
    source_url = value(row, item, :source_url)
    preview_graph_state = value(row, item, :preview_graph_state)
    preview_graph_types = array_value(row, item, :preview_graph_types)

    item.name = value(row, item, :name)
    item.format = value(row, item, :format)
    item.license_id = license.id if license
    item.text = value(row, item, :text)
    item.order = value(row, item, :order).to_i
    item.source_url = source_url if source_url.present?

    item.preview_graph_state = (preview_graph_state == I18n.t("ss.options.state.enabled")) ? "enabled" : "disabled"

    graph_types = I18n.t("opendata.graph_types").to_h.invert
    item.preview_graph_types = preview_graph_types.map { |type| graph_types[type].to_s }.select(&:present?)

    # file
    if file_name.present?
      path = "#{@datasets_dir}/#{@dataset_id}/#{@resource_id}/*"
      file_path = Dir.glob(path).select { |f| ::File.file?(f) }.first

      if file_path.present?
        item.in_file = Fs::UploadedFile.create_from_file(file_path)
      else
        put_log("-- resource.#{@resource_index} : not_found file_path #{format_log_path(path)}")
      end
    end

    # tsv file
    if tsv_name.present?
      path = "#{@datasets_dir}/#{@dataset_id}/#{@resource_id}/tsv/*"
      file_path = Dir.glob(path).select { |f| ::File.file?(f) }.first

      if file_path.present?
        item.in_tsv = Fs::UploadedFile.create_from_file(file_path)
      else
        put_log("-- resource.#{@resource_index} : not_found tsv_file_path #{format_log_path(path)}")
      end
    end

    item
  end
end
