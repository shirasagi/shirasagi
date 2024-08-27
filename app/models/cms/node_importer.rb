class Cms::NodeImporter
  include Cms::CsvImportBase

  attr_reader :site, :node, :user

  self.required_headers = %w(filename route).map { |v| I18n.t("cms.node_columns.#{v}") }

  def initialize(site, node, user)
    @site = site
    @node = node
    @user = user
  end

  def import(file, opts = {})
    @task = opts[:task]
    @keep_timestamp = opts[:keep_timestamp]
    basename = ::File.basename(file.name)
    put_log("import start #{basename}")
    Rails.logger.tagged(basename) do
      import_csv(file)
    end
  end

  def put_log(message)
    if @task
      @task.log(message)
    else
      puts message
    end
    Rails.logger.info(message)
  end

  def import_csv(file)
    self.class.each_csv(file) do |row, i|
      i += 1
      item = update_record(row)
      if item.errors.empty?
        put_log("update #{i + 1}行目: #{item.name}")
      else
        put_log("error #{i + 1}行目: #{item.errors.full_messages.join(', ')}")
      end
    rescue => e
      put_log("error  #{i + 1}行目: #{e}")
    end
  end

  def t_columns(key)
    I18n.t("cms.node_columns.#{key}")
  end

  def update_record(row)
    item = find_or_initialize_node(row)
    raise "ファイル名またはフォルダー属性が不正です" if item.nil?

    # basic
    item.name = row[t_columns(:name)] if item.respond_to?(:name)
    item.index_name = row[t_columns(:index_name)] if item.respond_to?(:index_name)
    item.order = row[t_columns(:order)] if item.respond_to?(:order)
    update_layout(row, item)
    update_page_layout(row, item)
    update_shortcut(row, item)
    update_view_route(row, item)

    # meta addon
    item.keywords = row[t_columns(:keywords)].to_s.split("\n") if item.respond_to?(:keywords)
    item.description = row[t_columns(:description)] if item.respond_to?(:description)
    item.summary_html = row[t_columns(:summary_html)] if item.respond_to?(:summary_html)

    # list addon
    item.conditions = row[t_columns(:conditions)].to_s.split("\n") if item.respond_to?(:conditions)
    update_sort(row, item)
    item.limit = row[t_columns(:limit)] if item.respond_to?(:limit)
    item.new_days = row[t_columns(:new_days)] if item.respond_to?(:new_days)
    update_loop_format(row, item)
    item.upper_html = row[t_columns(:upper_html)] if item.respond_to?(:upper_html)
    item.loop_html = row[t_columns(:loop_html)] if item.respond_to?(:loop_html)
    item.lower_html = row[t_columns(:lower_html)] if item.respond_to?(:lower_html)
    item.loop_liquid = row[t_columns(:loop_liquid)] if item.respond_to?(:loop_liquid)
    update_no_items_display_state(row, item)
    item.substitute_html = row[t_columns(:substitute_html)] if item.respond_to?(:substitute_html)

    # category addon
    update_st_categories(row, item)

    # release addon
    update_released_type(row, item)
    item.released = row[t_columns(:released)] if item.respond_to?(:released)
    update_state(row, item)

    # cms groups addon
    update_groups(row, item)

    item.save
    item
  end

  def find_or_initialize_node(row)
    basename = row[t_columns(:filename)]
    route = row[t_columns(:route)]
    return nil if basename.blank? || route.blank?

    if node
      filename = ::File.join(node.filename, basename)
    else
      filename = basename
    end

    object = Cms::Node.site(site).where(filename: filename).first
    if object.nil?
      object = Cms::Node::Base.new
      object = object.becomes_with_route(route)
      object = object.class.new
    elsif object.route != route
      object = object.becomes_with_route(route)
      object.route = route
    end
    return nil if object.instance_of?(Cms::Node::Base)

    object.cur_site = site
    object.cur_node = node if node
    object.filename = filename
    object
  end

  # options
  def update_shortcut(row, item)
    return if !item.respond_to?(:shortcut)
    return if !item.respond_to?(:shortcut_options)
    return if row[t_columns(:shortcut)].blank?

    options = item.shortcut_options.to_h
    item.shortcut = options[row[t_columns(:shortcut)]]
  end

  def update_view_route(row, item)
    return if !item.respond_to?(:view_route)
    return if !item.respond_to?(:view_route_options)
    return if row[t_columns(:view_route)].blank?

    options = item.view_route_options.to_h
    item.view_route = options[row[t_columns(:view_route)]]
  end

  def update_sort(row, item)
    return if !item.respond_to?(:sort)
    return if !item.respond_to?(:sort_options)
    return if row[t_columns(:sort)].blank?

    options = item.sort_options.to_h { |v| v.take(2) }
    item.sort = options[row[t_columns(:sort)]]
  end

  def update_loop_format(row, item)
    return if !item.respond_to?(:loop_format)
    return if !item.respond_to?(:loop_format_options)
    return if row[t_columns(:loop_format)].blank?

    options = item.loop_format_options.to_h
    item.loop_format = options[row[t_columns(:loop_format)]]
  end

  def update_released_type(row, item)
    return if !item.respond_to?(:released_type)
    return if !item.respond_to?(:released_type_options)
    return if row[t_columns(:released_type)].blank?

    options = item.released_type_options.to_h
    item.released_type = options[row[t_columns(:released_type)]]
  end

  def update_no_items_display_state(row, item)
    return if !item.respond_to?(:no_items_display_state)
    return if !item.respond_to?(:no_items_display_state_options)
    return if row[t_columns(:no_items_display_state)].blank?

    options = item.no_items_display_state_options.to_h
    item.no_items_display_state = options[row[t_columns(:no_items_display_state)]]
  end

  def update_state(row, item)
    return if !item.respond_to?(:state)
    return if !item.respond_to?(:state_options)

    options = item.state_options.to_h
    item.state = options[row[t_columns(:state)]]
  end

  # relations
  def update_layout(row, item)
    return if !item.respond_to?(:layout)
    return if row[t_columns(:layout_filename)].blank?

    layout_filename_match = row[t_columns(:layout_filename)].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.site(site).find_by(filename: layout_filename) rescue nil
    item.layout = layout
  end

  def update_page_layout(row, item)
    return if !item.respond_to?(:page_layout)
    return if row[t_columns(:page_layout_filename)].blank?

    layout_filename_match = row[t_columns(:page_layout_filename)].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.site(site).find_by(filename: layout_filename) rescue nil
    item.page_layout = layout
  end

  def update_st_categories(row, item)
    return if !item.respond_to?(:st_category_ids)
    return if row[t_columns(:st_category_ids)].blank?

    st_category_ids = []
    row[t_columns(:st_category_ids)].split("\n").each do |filename|
      filename_match = filename.match(/\(([^)]+)\)/)
      next if filename_match.nil?

      filename = filename_match[1]
      category = Category::Node::Base.site(site).find_by(filename: filename) rescue nil
      next if category.nil?

      st_category_ids << category.id
    end
    item.st_category_ids = st_category_ids
  end

  def update_groups(row, item)
    return if !item.respond_to?(:group_ids)
    return if row[t_columns(:group_ids)].blank?

    @group_name_group_map ||= Cms::Group.all.site(@site).to_a.index_by(&:name)

    names = row[t_columns(:group_ids)].split("\n").map(&:strip)
    groups = names.filter_map { |name| @group_name_group_map[name] }
    item.group_ids = groups.map(&:id)
  end
end
