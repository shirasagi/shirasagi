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
    # to insert item into array, use `#persist_atomic_operations` method.
    # be careful, you must not use `#set` method. this method update hash totally.
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
    # to update hash (item of array) partially, use mongodb native method.
    # be careful, you must not use `#set` method. this method update hash totally.
    filter_spec = { _id: self.id, user_settings: { "$elemMatch" => { "user_id" => user_id } } }
    update_spec = { "$set" => { "user_settings.$.#{state}" => value } }
    self.collection.update_one(filter_spec, update_spec)

    user_setting = bsearch_user_setting(user_id)
    user_setting[state] = value
  end

  def upsert_user_setting(user_id, state, value)
    if user_settings.blank?
      insert_user_setting(user_id, state, value)
      return
    end

    user_setting = bsearch_user_setting(user_id)
    if user_setting.blank?
      insert_user_setting(user_id, state, value)
      return
    end

    update_user_setting(user_id, state, value)
  end

  def delete_user_setting(user_id, state)
    user_setting = bsearch_user_setting(user_id)
    return if user_setting.blank?

    save = user_setting.delete(state)
    user_setting.delete_if { |_key, value| value.nil? }
    if user_setting.keys.length == 1 && user_setting.keys.first == "user_id"
      # all states have been deleted --> remove hash from array
      filter_spec = { _id: self.id }
      update_spec = { "$pull" => { user_settings: { user_id: user_id } } }
      self.collection.update_one(filter_spec, update_spec)
      self.user_settings.delete(user_setting)
    elsif save
      # some states remains --> unset value of hash in array (unset means set nil)
      filter_spec = { _id: self.id, user_settings: { "$elemMatch" => { "user_id" => user_id } } }
      update_spec = { "$unset" => { "user_settings.$.#{state}" => "" } }
      self.collection.update_one(filter_spec, update_spec)
    end

    save
  end

  def find_user_setting(user_id, state)
    user_setting = bsearch_user_setting(user_id)
    return if user_setting.blank?

    user_setting[state]
  end

  def bsearch_user_setting(user_id)
    return if user_settings.blank?
    user_settings.bsearch { |user_setting| user_id <=> user_setting["user_id"] }
  end
end
