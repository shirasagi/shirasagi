class History::Backup::SweepJob < SS::ApplicationJob
  def perform
    now = Time.zone.now.beginning_of_day
    duration = SS::Duration.parse(SS.config.ss.keep_history_backup_after_destroyed)
    created = now - duration
    Rails.logger.info("データベース上から削除されたページ、フォルダー、レイアウト、パーツに関連した操作履歴のうち、#{created.iso8601} 以前に作成されたものを削除します。")

    each_backup(created) do |backup|
      item_id = backup.data[:_id]
      next if item_id.blank?

      item_name = backup.data[:name]
      item_filename = backup.data[:filename]

      case backup.ref_coll
      when "cms_pages"
        if page_deleted?(item_id)
          Rails.logger.info("ページ #{item_name}(#{item_filename}; #{item_id}) がデータベース上に存在しないので、履歴を削除します。")
          backup.destroy
        end
      when "cms_nodes"
        if node_deleted?(item_id)
          Rails.logger.info("フォルダー #{item_name}(#{item_filename}; #{item_id}) がデータベース上に存在しないので、履歴を削除します。")
          backup.destroy
        end
      when "cms_layouts"
        if layout_deleted?(item_id)
          Rails.logger.info("レイアウト #{item_name}(#{item_filename}; #{item_id}) がデータベース上に存在しないので、履歴を削除します。")
          backup.destroy
        end
      when "cms_parts"
        if part_deleted?(item_id)
          Rails.logger.info("パーツ #{item_name}(#{item_filename}; #{item_id}) がデータベース上に存在しないので、履歴を削除します。")
          backup.destroy
        end
      end
    end
  end

  private

  def each_backup(created, &block)
    criteria = ::History::Backup.all.unscoped.lt(created: created)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end

  def all_page_ids
    @all_page_ids ||= ::Cms::Page.all.unscoped.pluck(:id)
  end

  def all_node_ids
    @all_node_ids ||= ::Cms::Node.all.unscoped.pluck(:id)
  end

  def all_layout_ids
    @all_layout_ids ||= ::Cms::Layout.all.unscoped.pluck(:id)
  end

  def all_part_ids
    @all_part_ids ||= ::Cms::Part.all.unscoped.pluck(:id)
  end

  def page_deleted?(item_id)
    !all_page_ids.include?(item_id)
  end

  def node_deleted?(item_id)
    !all_node_ids.include?(item_id)
  end

  def layout_deleted?(item_id)
    !all_layout_ids.include?(item_id)
  end

  def part_deleted?(item_id)
    !all_part_ids.include?(item_id)
  end
end
