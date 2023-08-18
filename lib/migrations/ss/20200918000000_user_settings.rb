class SS::Migration20200918000000
  include SS::Migration::Base

  depends_on "20200630000000"

  def change
    each_item do |item|
      deleted = item.attributes["deleted"]
      seen = item.attributes["seen"]
      user_settings = item[:user_settings].presence || []
      user_settings_modified = false
      if deleted.present? && deleted.is_a?(Hash)
        deleted.each do |str_user_id, time|
          upsert_user_setting(user_settings, str_user_id.to_i, "deleted", time)
        end
        user_settings_modified = true
      end
      if seen.present?
        seen.each do |str_user_id, time|
          upsert_user_setting(user_settings, str_user_id.to_i, "seen_at", time)
        end
        user_settings_modified = true
      end

      if user_settings_modified
        user_settings.sort_by! { |user_state| user_state["user_id"] }
        item.set(user_settings: user_settings)
      end

      if deleted.present? && deleted.is_a?(Hash) && seen.present?
        item.unset(:deleted, :seen)
      elsif deleted.present? && deleted.is_a?(Hash)
        item.unset(:deleted)
      elsif seen.present?
        item.unset(:seen)
      end
    end
  end

  private

  def each_item(&block)
    criteria = SS::Notification.all
    criteria = criteria.where(
      "$and" => [{ "$or" => [{ "deleted" => { "$exists" => true } }, { "seen" => { "$exists" => true } }] }]
    )
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end

  def upsert_user_setting(user_settings, user_id, state, value)
    found = false
    user_settings.each do |user_setting|
      if user_setting["user_id"] == user_id
        user_setting[state] = value
        found = true
      end
    end

    return if found

    user_settings << { "user_id" => user_id, state => value }
  end
end
