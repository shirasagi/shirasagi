module Tasks
  module History
    class << self
      def sweep_backup
        each_backup(Time.zone.now.beginning_of_day - 2.weeks) do |backup|
          item_id = backup.data[:_id]
          next if item_id.blank?

          item_name = backup.data[:name]
          item_filename = backup.data[:filename]

          case backup.ref_coll
          when "cms_pages"
            if !all_page_ids.include?(item_id)
              puts "ページ #{item_name}(#{item_filename}; #{item_id}) は見つかりません。"
              backup.destroy
            end
          when "cms_nodes"
            if !all_node_ids.include?(item_id)
              puts "フォルダー #{item_name}(#{item_filename}; #{item_id}) は見つかりません。"
              backup.destroy
            end
          when "cms_layouts"
            if !all_layout_ids.include?(item_id)
              puts "レイアウト #{item_name}(#{item_filename}; #{item_id}) は見つかりません。"
              backup.destroy
            end
          when "cms_parts"
            if !all_part_ids.include?(item_id)
              puts "パーツ #{item_name}(#{item_filename}; #{item_id}) は見つかりません。"
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
    end
  end
end
