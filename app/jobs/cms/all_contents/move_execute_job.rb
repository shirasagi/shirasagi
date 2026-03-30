class Cms::AllContents::MoveExecuteJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents_moves"

  HISTORY_RETENTION_PERIOD = 2.weeks

  def perform(selected_ids)
    check_results = load_check_result
    move_results = []
    @url_mappings = []

    selected_items = check_results.select { |r| selected_ids.include?(r["id"]) }
    selected_items.each do |item|
      result = execute_move(item)
      move_results << result
      task.log "#{result[:status]}: id=#{item['id']} #{item['filename']} -> #{item['destination']}"
      task.count
    end

    save_move_result(move_results)
    apply_attribute_changes(selected_items)
    replace_urls_after_move
    save_history(move_results)
    cleanup_old_histories
  end

  private

  def execute_move(item)
    page = Cms::Page.site(site).where(id: item["id"]).first
    unless page
      return { row: item["row"], id: item["id"], status: "error",
               errors: [I18n.t('cms.all_contents_moves.errors.page_not_found')] }
    end

    page.cur_site = site
    page.cur_user = user

    service = Cms::Page::MoveService.new(
      cur_site: site, cur_user: user,
      page: page, destination: item["destination"],
      skip_replace_urls_job: true
    )

    if service.move
      @url_mappings << service.url_mappings if service.url_mappings
      result = { row: item["row"], id: item["id"],
        filename: item["destination"], status: "ok" }
      result[:confirmations] = item["confirmations"] if item["confirmations"].present?
      result
    else
      { row: item["row"], id: item["id"],
        filename: item["destination"], status: "error",
        errors: service.errors.full_messages }
    end
  end

  def apply_attribute_changes(items)
    items.each do |item|
      page = Cms::Page.site(site).where(id: item["id"]).first
      next unless page

      changed = apply_basic_changes(page, item)
      changed = apply_meta_changes(page, item) || changed
      changed = apply_category_changes(page, item) || changed
      changed = apply_crumb_changes(page, item) || changed
      changed = apply_contact_changes(page, item) || changed
      changed = apply_group_changes(page, item) || changed

      if changed && !page.save
        task.log "属性変更の保存に失敗: id=#{page.id} #{page.errors.full_messages.join(', ')}"
      end
    end
  end

  def apply_basic_changes(page, item)
    changed = false

    if item["name"].present? && item["name"] != page.name
      page.name = item["name"]
      changed = true
    end

    if item.key?("index_name") && item["index_name"] != page.index_name
      page.index_name = item["index_name"]
      changed = true
    end

    if item["layout"].present?
      layout = Cms::Layout.site(site).where(filename: item["layout"]).first
      if layout && layout.id != page.layout_id
        page.layout_id = layout.id
        changed = true
      end
    end

    if item["order"].present? && item["order"].to_i != page.order
      page.order = item["order"].to_i
      changed = true
    end

    changed
  end

  def apply_meta_changes(page, item)
    changed = false

    if item["keywords"].present?
      new_keywords = item["keywords"].split(/[,、]/).map(&:strip)
      if new_keywords != page.try(:keywords)
        page.keywords = new_keywords
        changed = true
      end
    end

    if item.key?("description") && item["description"] != page.try(:description)
      page.description = item["description"]
      changed = true
    end

    if item.key?("summary_html") && item["summary_html"] != page.try(:summary_html)
      page.summary_html = item["summary_html"]
      changed = true
    end

    changed
  end

  def apply_category_changes(page, item)
    return false unless item["category_names"].present?
    return false unless page.respond_to?(:category_ids)

    filenames = item["category_names"].split("\n").map(&:strip)
    nodes = filenames.filter_map do |fn|
      Cms::Node.site(site).where(filename: fn).first
    end

    if nodes.map(&:id).sort != page.category_ids.sort
      page.category_ids = nodes.map(&:id)
      return true
    end

    false
  end

  def apply_crumb_changes(page, item)
    return false unless item.key?("parent_crumb_urls")
    return false unless page.respond_to?(:parent_crumb_urls)

    new_urls = item["parent_crumb_urls"].to_s.split("\n").map(&:strip).reject(&:blank?)
    if new_urls != page.parent_crumb_urls
      page.parent_crumb_urls = new_urls
      return true
    end

    false
  end

  def apply_contact_changes(page, item)
    return false unless page.respond_to?(:contact_state)

    changed = false

    contact_fields = %w[
      contact_state contact_group_name contact_charge
      contact_tel contact_fax contact_email
      contact_postal_code contact_address
      contact_link_url contact_link_name
      contact_group_relation
    ]

    contact_fields.each do |field|
      next unless item.key?(field)
      next if item[field] == page.send(field)

      page.send("#{field}=", item[field])
      changed = true
    end

    # 所属グループ（contact_group）: グループ名からIDへ変換
    if item["contact_group"].present?
      group = Cms::Group.where(name: item["contact_group"]).first
      if group && group.id != page.contact_group_id
        page.contact_group_id = group.id
        changed = true
      end
    end

    # 連絡先窓口（contact_group_contact）: 所属グループ内の連絡先名からIDへ変換
    if item["contact_group_contact"].present? && page.contact_group.present?
      contact = page.contact_group.contact_groups.where(name: item["contact_group_contact"]).first
      if contact && contact.id != page.contact_group_contact_id
        page.contact_group_contact_id = contact.id
        changed = true
      end
    end

    # 所属（組織一覧用）: グループ名からIDへ変換
    if item["contact_sub_group_names"].present? && page.respond_to?(:contact_sub_group_ids)
      group_names = item["contact_sub_group_names"].split("\n").map(&:strip)
      groups = group_names.filter_map { |name| Cms::Group.where(name: name).first }
      if groups.map(&:id).sort != page.contact_sub_group_ids.sort
        page.contact_sub_group_ids = groups.map(&:id)
        changed = true
      end
    end

    changed
  end

  def apply_group_changes(page, item)
    return false unless item["group_names"].present?
    return false unless page.respond_to?(:group_ids=)

    group_names = item["group_names"].split("\n").map(&:strip)
    groups = group_names.filter_map do |name|
      Cms::Group.where(name: name).first
    end

    if groups.map(&:id).sort != page.group_ids.sort
      page.group_ids = groups.map(&:id)
      return true
    end

    false
  end

  # 全移動完了後にURL置換ジョブをまとめて実行する
  def replace_urls_after_move
    return unless SS.config.cms.replace_urls_after_move
    return if @url_mappings.blank?

    @url_mappings.each do |mapping|
      Cms::Page::MoveJob.bind(site_id: site, user_id: user)
        .perform_later(src: mapping[:src], dst: mapping[:dst])
    rescue Job::SizeLimitPerUserExceededError => e
      task.log "URL置換ジョブのキューイングに失敗: #{e.message} (src: #{mapping[:src]})"
    end
  end

  def load_check_result
    path = ::File.join(task.base_dir, "check_result.json")
    JSON.parse(::File.read(path))
  end

  def save_move_result(results)
    dir = task.base_dir
    FileUtils.mkdir_p(dir)
    path = ::File.join(dir, "move_result.json")
    ::File.write(path, results.to_json)
  end

  def save_history(move_results)
    history_dir = ::File.join(task.base_dir, "histories")
    FileUtils.mkdir_p(history_dir)

    timestamp = Time.zone.now.strftime("%Y%m%d_%H%M%S")
    user_name = user.try(:uid) || user.try(:id)
    entry_dir = ::File.join(history_dir, "#{timestamp}_#{user_name}")
    FileUtils.mkdir_p(entry_dir)

    history_meta = {
      executed_at: Time.zone.now.iso8601,
      user_id: user.try(:id),
      user_name: user.try(:long_name) || user.try(:name),
      total: move_results.size,
      ok: move_results.count { |r| r[:status] == "ok" },
      error: move_results.count { |r| r[:status] == "error" }
    }

    ::File.write(::File.join(entry_dir, "meta.json"), history_meta.to_json)
    ::File.write(::File.join(entry_dir, "move_result.json"), move_results.to_json)
  end

  def cleanup_old_histories
    history_dir = ::File.join(task.base_dir, "histories")
    return unless ::Dir.exist?(history_dir)

    cutoff = Time.zone.now - HISTORY_RETENTION_PERIOD
    ::Dir.children(history_dir).each do |entry|
      entry_path = ::File.join(history_dir, entry)
      next unless ::File.directory?(entry_path)

      meta_path = ::File.join(entry_path, "meta.json")
      next unless ::File.exist?(meta_path)

      meta = JSON.parse(::File.read(meta_path))
      executed_at = Time.zone.parse(meta["executed_at"]) rescue nil
      next unless executed_at

      if executed_at < cutoff
        FileUtils.rm_rf(entry_path)
      end
    end
  end
end
