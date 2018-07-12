class Cms::AllContentsImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter
  include SS::ZipFileImport

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents"

  before_perform :load_keys

  SKIP_FIELDS = %w(page_id node_id route url files file_urls use_map created updated file_size).freeze

  private

  def load_keys
    @field_defs = I18n.t("all_content").map { |key, value| [ value, key.to_s ] }
    @states = I18n.t("ss.options.state").map { |key, value| [ value, key.to_s ] }
  end

  def import_file
    @table = ::CSV.read(@cur_file.path, headers: true, encoding: 'SJIS:UTF-8')
    @table.each_with_index do |row, i|
      import_row(row, i + 1)
    end
    nil
  end

  def val(row, key)
    row[I18n.t("all_content.#{key}")].presence
  end

  def import_row(row, row_number)
    item = load_content(row)
    if item.blank?
      Rails.logger.info("#{row_number} 行のコンテンツは見つかりませんでした。")
      return
    end

    import_item(item.becomes_with_route, row)
  rescue => e
    Rails.logger.info("#{row_number} 行のコンテンツは見つかりませんでした。")
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  end

  def load_content(row)
    page_id = val(row, "page_id")
    if page_id
      return Cms::Page.site(site).find(page_id)
    end

    node_id = val(row, "node_id")
    if node_id
      return Cms::Node.site(site).find(node_id)
    end
  end

  def import_item(item, row)
    @field_defs.each do |header, key|
      next if SKIP_FIELDS.include?(key)
      next if !@table.headers.include?(header)

      import_method = "set_#{key}"
      if respond_to?(import_method, true)
        send(import_method, item, row)
      else
        set_simple_value(key, item, row)
      end
    end
    item.save!
    Rails.logger.info("#{item.filename}: コンテンツをインポートしました。")
    true
  rescue => e
    Rails.logger.info("#{item.filename}: コンテンツをインポートできませんでした。")
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  end

  def set_simple_value(key, item, row)
    if item.respond_to?("#{key}=")
      item.send("#{key}=", val(row, key))
    end
  end

  def set_layout(item, row)
    return if !item.respond_to?("layout_id=")

    filename = val(row, "layout")
    layout = Cms::Layout.site(site).where(filename: filename).first if filename
    item.layout_id = layout ? layout.id : nil
  end

  def set_loop_setting_id(item, row)
    return if !item.respond_to?("loop_setting_id=")

    loop_setting_name = val(row, "loop_setting_id")
    if loop_setting_name == I18n.t("cms.input_directly")
      item.loop_setting_id = nil
    else
      loop_setting = Cms::LoopSetting.site(site).where(name: loop_setting_name).first
      item.loop_setting_id = loop_setting ? loop_setting.id : nil
    end
  end

  def set_category_ids(item, row)
    return if !item.respond_to?("category_ids=")

    categories = val(row, "category_ids")
    categories = categories.split(/[, 　、\r\n]+/) if categories
    categories ||= []

    category_filenames = categories.map { |category| category.sub(/[ \t\(].*$/, '') }
    item.category_ids = Cms::Node.site(site).in(filename: category_filenames).pluck(:id)
  end

  def set_group_names(item, row)
    return if !item.respond_to?("group_ids=")

    group_names = val(row, "group_names")
    group_names = group_names.split(/[, 　、\r\n]+/) if group_names
    group_names ||= []

    item.group_ids = Cms::Group.site(site).where("$and" =>[{ name: { "$in" => group_names } }]).pluck(:id)
  end

  def set_close_date(item, row)
    return if !item.respond_to?("close_date=")

    val = val(row, "close_date")
    time = Time.zone.parse(val) if val
    item.close_date = time
  end

  def find_status(label)
    return if label.blank?

    ret = @states.find { |val, key| val == label }
    return if ret.blank?

    ret[1]
  end

  def set_status(item, row)
    return if !item.respond_to?("state=")

    status = val(row, "status")
    item.state = find_status(status)
  end
end
