module SS::UserSettings
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :user_settings, type: Array
  end

  module ClassMethods
    def and_user_setting_blank(user_or_user_id, state)
      user_id = user_or_user_id.numeric? ? user_or_user_id.to_i : user_or_user_id.id
      where(user_settings: { "$not" => { "$elemMatch" => { "user_id" => user_id, state => { "$exists" => true } } } })
    end

    def and_user_setting_present(user_or_user_id, state)
      user_id = user_or_user_id.numeric? ? user_or_user_id.to_i : user_or_user_id.id
      where(user_settings: { "$elemMatch" => { "user_id" => user_id, state => { "$exists" => true } } })
    end
  end

  private

  def insert_user_setting(user_id, state, value)
    persist_atomic_operations(
      "$push" => {
        user_settings: {
          "$each" => [{ "user_id" => user_id, state => value }],
          "$sort" => { user_id: 1 }
        }
      }
    )

    if self.user_settings.blank?
      self.user_settings = [{ "user_id" => user_id, state => value }]
    else
      self.user_settings << { "user_id" => user_id, state => value }
      self.user_settings.sort_by! { |user_state| user_state["user_id"] }
    end
  end

  def update_user_setting(user_id, state, value)
    filter_spec = { _id: self.id, user_settings: { "$elemMatch" => { "user_id" => user_id } } }
    update_spec = { "$set" => { "user_settings.$.#{state}" => value } }
    self.collection.update_one(filter_spec, update_spec)

    user_setting = user_settings.bsearch { |user_setting| user_setting["user_id"] <=> user_id }
    user_setting[state] = value
  end

  def upsert_user_setting(user_id, state, value)
    if user_settings.blank?
      insert_user_setting(user_id, state, value)
      return
    end

    user_setting = user_settings.bsearch { |user_setting| user_setting["user_id"] <=> user_id }
    if user_setting.blank?
      insert_user_setting(user_id, state, value)
      return
    end

    update_user_setting(user_id, state, value)
  end

  def find_user_setting(user_id, state)
    return if user_settings.blank?

    user_setting = user_settings.bsearch { |user_setting| user_id <=> user_setting["user_id"] }
    return if user_setting.blank?

    user_setting[state]
  end
end
