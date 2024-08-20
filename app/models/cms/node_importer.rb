class Cms::NodeImporter
  include Cms::CsvImportBase

  attr_reader :site, :node, :user

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
      Rails.logger.tagged("#{i + 1}行目") do
        item = update_record(row)
        put_log("update #{i + 1}: #{item.name}") if item.present?
      rescue => e
        put_log("error  #{i + 1}: #{e}")
      end
    end
  end

  def update_record(row)
    item = find_or_initialize_node(row)

    item.name = row[I18n.t('cms.node_columns.name')] if item.respond_to?(:name)
    item.index_name = row[I18n.t('cms.node_columns.index_name')] if item.respond_to?(:index_name)
    item.order = row[I18n.t('cms.node_columns.order')] if item.respond_to?(:order)

    update_layout(row, item) if item.respond_to?(:layout)
    update_page_layout(row, item) if item.respond_to?(:page_layout)

    item.shortcut = row[I18n.t('cms.node_columns.shortcut')] if item.respond_to?(:shortcut)
    item.view_route = row[I18n.t('cms.node_columns.view_route')] if item.respond_to?(:view_route)
    item.keywords = row[I18n.t('cms.node_columns.keywords')].split(',').map(&:strip) if row[I18n.t('cms.node_columns.keywords')] && item.respond_to?(:keywords)
    item.description = row[I18n.t('cms.node_columns.description')] if item.respond_to?(:description)
    item.summary_html = row[I18n.t('cms.node_columns.summary_html')] if item.respond_to?(:summary_html)
    item.conditions = row[I18n.t('cms.node_columns.conditions')] if item.respond_to?(:conditions)
    item.sort = row[I18n.t('cms.node_columns.sort')] if item.respond_to?(:sort)
    item.limit = row[I18n.t('cms.node_columns.limit')] if item.respond_to?(:limit)
    item.new_days = row[I18n.t('cms.node_columns.new_days')] if item.respond_to?(:new_days)
    item.loop_format = row[I18n.t('cms.node_columns.loop_format')] if item.respond_to?(:loop_format)
    item.upper_html = row[I18n.t('cms.node_columns.upper_html')] if item.respond_to?(:upper_html)
    item.loop_html = row[I18n.t('cms.node_columns.loop_html')] if item.respond_to?(:loop_html)
    item.lower_html = row[I18n.t('cms.node_columns.lower_html')] if item.respond_to?(:lower_html)
    item.loop_liquid = row[I18n.t('cms.node_columns.loop_liquid')] if item.respond_to?(:loop_liquid)
    item.no_items_display_state = row[I18n.t('cms.node_columns.no_items_display_state')] if item.respond_to?(:no_items_display_state)
    item.substitute_html = row[I18n.t('cms.node_columns.substitute_html')] if item.respond_to?(:substitute_html)
    item.category_ids = row[I18n.t('cms.node_columns.category_ids')].split(',').map(&:strip) if row[I18n.t('cms.node_columns.category_ids')] && item.respond_to?(:category_ids)
    item.released_type = row[I18n.t('cms.node_columns.released_type')] if item.respond_to?(:released_type)
    item.released = row[I18n.t('cms.node_columns.released')] if item.respond_to?(:released)
    item.state = row[I18n.t('cms.node_columns.state')] if item.respond_to?(:state)

    item.for_member_state = 'enabled' if item.respond_to?(:for_member_state)

    update_groups(row, item)

    item.save!
    item
  end

  def find_or_initialize_node(row)
    basename = row[I18n.t('cms.node_columns.filename')]
    return nil if basename.blank?
    if @node
      filename = ::File.join(@node.filename, basename)
    else
      filename = basename
    end

    object = Cms::Node.site(@site).where(filename: filename).first
    if object.nil?
      route = row[I18n.t('cms.node_columns.route')]
      object = Cms::Node::Base.new(route: route)
      object = object.becomes_with_route(route)

      if object.class == Cms::Node::Base
        raise "unknown route given (#{route})"
      end
    end

    object.cur_site = @site
    object.cur_node = @node if @node
    object.filename = filename
    object
  end

  def update_layout(row, item)
    return if row[I18n.t('cms.node_columns.layout_filename')].blank?

    layout_filename_match = row[I18n.t('cms.node_columns.layout_filename')].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.find_by(filename: layout_filename) rescue nil
    item.layout = layout
  end

  def update_page_layout(row, item)
    return if row[I18n.t('cms.node_columns.page_layout_filename')].blank?

    layout_filename_match = row[I18n.t('cms.node_columns.page_layout_filename')].match(/\(([^)]+)\)/)
    layout_filename = layout_filename_match[1] if layout_filename_match
    layout = Cms::Layout.find_by(filename: layout_filename) rescue nil
    item.page_layout = layout
  end

  def update_groups(row, item)
    return if row[I18n.t('cms.node_columns.group_ids')].blank?

    @group_name_group_map ||= Cms::Group.all.site(@site).to_a.index_by(&:name)

    names = row[I18n.t('cms.node_columns.group_ids')].split("\n").map(&:strip)
    groups = names.filter_map { |name| @group_name_group_map[name] }
    item.group_ids = groups.map(&:id)
  end
end