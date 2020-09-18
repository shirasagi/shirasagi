class SS::Migration20200918000000
  include SS::Migration::Base

  depends_on "20200630000000"

  def change
    each_item do |item|
      deleted = item.attributes["deleted"]
      seen = item.attributes["seen"]
      user_states = item[:user_states].presence || []
      user_states_modified = false
      if deleted.present? && deleted.is_a?(Hash)
        deleted.each do |str_user_id, time|
          upsert_user_state(user_states, str_user_id.to_i, "deleted", time)
        end
        user_states_modified = true
      end
      if seen.present?
        seen.each do |str_user_id, time|
          upsert_user_state(user_states, str_user_id.to_i, "seen", time)
        end
        user_states_modified = true
      end

      if user_states_modified
        user_states.sort_by! { |user_state| user_state["user_id"] }
        item.set(user_states: user_states)
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

  def upsert_user_state(user_states, user_id, state, value)
    found = false
    user_states.each do |user_state|
      if user_state["user_id"] == user_id
        user_state[state] = value
        found = true
      end
    end

    return if found

    user_states << { "user_id" => user_id, state => value }
  end
end
