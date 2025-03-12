# ref_id を設定する
class SS::Migration20250310000000
  include SS::Migration::Base

  depends_on "20240913000000"

  def change
    each_item do |item|
      next if item.data.blank?

      id = item.data["_id"]
      next if id.blank?

      item.set(ref_id: id)
    end
  end

  private

  def each_item(&block)
    History::Backup.unscoped.tap do |criteria|
      criteria = criteria.exists(ref_id: false)
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        criteria.in(id: ids).to_a.each(&block)
      end
    end

    History::Trash.unscoped.tap do |criteria|
      criteria = criteria.exists(ref_id: false)
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(100) do |ids|
        criteria.in(id: ids).to_a.each(&block)
      end
    end
  end
end
