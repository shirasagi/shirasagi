class Opendata::Dataset::ImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "opendata:import_datasets"

  def perform(ss_file_id)
    @file = SS::File.find(ss_file_id)
    prepare_temp_dir
    task.tagged(::File.basename(@file.name)) do
      task.log "start importing"

      zip_each_datasets_csv do |datasets_csv_table, datasets_csv_dir|
        task.tagged("#{datasets_csv_dir}/datasets.csv") do
          dataset_import_csv(datasets_csv_table, datasets_csv_dir)
        end
      end

      task.log "finish importing"
    end
  ensure
    @file.destroy rescue nil
    FileUtils.rm_rf(temp_dir) rescue nil
  end

  private

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site.id
    cond[:node_id] = node.id
    cond
  end

  def temp_dir
    # use "tmp" directory.
    #
    # "private" directory is sometimes mounted via NFS and NFS is too slow.
    # so "private" directory isn't right and "tmp" directory is preferable.
    @temp_dir ||= "#{Rails.root}/tmp/opendata-datasets-#{task.id}-#{Time.zone.now.to_i}"
  end

  def prepare_temp_dir
    FileUtils.rm_rf(temp_dir)
    FileUtils.mkdir_p(temp_dir)
  end

  #
  # Zip Utility Methods
  #

  def zip_file
    @zip_file ||= Zip::File.open(@file.path)
  end

  def zip_each_datasets_csv
    @zip_datasets_count ||= 0
    zip_file.each do |datasets_csv_entry|
      datasets_csv_path = zip_normalize_entry_name(datasets_csv_entry)
      next unless datasets_csv_path.end_with?("/datasets.csv")

      temp_name = "#{temp_dir}/datasets-#{@zip_datasets_count}.csv"
      ::File.open(temp_name, "wb") do |f|
        IO.copy_stream(datasets_csv_entry.get_input_stream, f)
      end
      @zip_datasets_count += 1

      ::SS::Csv.open(temp_name) do |csv_table|
        datasets_csv_dir = ::File.dirname(datasets_csv_path)
        datasets_csv_dir = "" if datasets_csv_dir == "."
        yield csv_table, datasets_csv_dir
      end
    end
  end

  def zip_find_entry(entry_path)
    zip_file.find_entry(entry_path)
  end

  def zip_normalize_entry_name(entry)
    name = entry.name
    if entry.gp_flags & Zip::Entry::EFS
      name.force_encoding("UTF-8")
    else
      name = NKF.nkf('-w', name)
    end
    name
  end

  def zip_first_file(pattern)
    found = nil
    zip_file.each do |entry|
      next unless entry.file?

      path = zip_normalize_entry_name(entry)
      next unless ::File.fnmatch(pattern, path.chomp('/'))

      found = entry
      break
    end
    found
  end

  #
  # Dataset Utility Methods
  #

  def dataset_import_csv(dataset_csv_table, datasets_csv_dir)
    dataset_csv_table.each.with_index do |row, i|
      task.tagged("#{i + 2}行目") do
        begin
          dataset_create(row, datasets_csv_dir)
        rescue => e
          task.log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        end
      end
    end
  end

  def dataset_create(row, datasets_csv_dir)
    dataset_id = value(row, Opendata::Dataset, :id).to_i
    if dataset_id <= 0
      task.log("dataset id is not found")
      return
    end

    dataset_item = dataset_initialize(row)
    unless dataset_item.save
      task.log("save failed #{dataset_item.name} #{dataset_item.errors.full_messages.join(", ")}")
      return
    end

    task.log("successfully saved #{dataset_item.name}(#{dataset_item.id})")

    resources_csv_entry = zip_find_entry "#{datasets_csv_dir}/#{dataset_id}/resources.csv"
    unless resources_csv_entry
      task.log("resources.csv is not found")
      return
    end

    @zip_resources_count ||= 0
    temp_name = "#{temp_dir}/resources-#{@zip_resources_count}.csv"
    ::File.open(temp_name, "wb") do |f|
      IO.copy_stream(resources_csv_entry.get_input_stream, f)
    end
    @zip_resources_count += 1

    ::SS::Csv.open(temp_name) do |resources_csv_table|
      resources_csv_path = zip_normalize_entry_name(resources_csv_entry)
      resources_csv_dir = ::File.dirname(resources_csv_path)
      task.tagged(resources_csv_path) do
        task.log("start importing resources")
        resource_import_csv(resources_csv_table, resources_csv_dir, dataset_item)
      end
    end
  end

  def dataset_initialize(row)
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
    item.contact_group_id = Cms::Group.site(site).where(name: value(row, item, :contact_group_id)).first.try(:id)
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

  #
  # Resource Utility Methods
  #

  def resource_import_csv(resources_csv_table, resources_csv_dir, dataset)
    resources_csv_table.each.with_index do |row, i|
      task.tagged("#{i + 2}行目") do
        resource_create(resources_csv_dir, dataset, row)
      rescue => e
        task.log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end

  def resource_create(resources_csv_dir, dataset, row)
    resource_id = value(row, Opendata::Resource, :id).to_i
    if resource_id <= 0
      task.log("resource id is not found")
      return nil
    end

    item = resource_initialize("#{resources_csv_dir}/#{resource_id}", dataset, row)
    if item.save
      task.log("successfully saved #{item.name}(#{item.id})")
      item
    else
      task.log("save failed #{item.name} #{item.errors.full_messages.join(", ")}")
      nil
    end
  end

  def resource_initialize(resources_csv_dir, dataset, row)
    item = dataset.resources.new

    license = Opendata::License.site(site).where(name: value(row, item, :license_id)).first
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
      file_entry = zip_first_file("#{resources_csv_dir}/*")
      if file_entry.present?
        file = create_file(file_entry)
        item.filename = file.filename
        item.file = file
      else
        task.log("resource file is not found in #{resources_csv_dir}")
      end
    end

    # tsv file
    if tsv_name.present?
      tsv_entry = zip_first_file("#{resources_csv_dir}/tsv/*")

      if tsv_entry.present?
        item.tsv = create_file(tsv_entry)
      else
        task.log("tsv file is not found in #{resources_csv_dir}")
      end
    end

    item
  end

  #
  # Common Utility Methods
  #

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

  def create_file(entry)
    path = zip_normalize_entry_name(entry)
    basename = ::File.basename(path)
    basename = SS::FilenameUtils.convert_to_url_safe_japanese(basename)
    SS::TempFile.create_empty!(model: 'ss/temp_file', filename: basename) do |new_file|
      IO.copy_stream(entry.get_input_stream, new_file.path)
    end
  end
end
