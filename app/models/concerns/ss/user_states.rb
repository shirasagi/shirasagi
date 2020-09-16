module SS::UserStates
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :user_states, type: Array
  end

  module ClassMethods
    def and_user_state_blank(user_or_user_id, state, exists = false)
      user_id = user_or_user_id.numeric? ? user_or_user_id.to_i : user_or_user_id.id
      where(user_states: { "$elemMatch" => { "user_id" => user_id, state => { "$exists" => exists } } })
    end

    def and_user_state_present(user_or_user_id, state)
      and_user_state_blank(user_or_user_id, state, true)
    end
  end

  private

  def insert_user_state(user_id, state, value)
    persist_atomic_operations(
      "$push" => {
        user_states: {
          "$each" => [{ "user_id" => user_id, state => value }],
          "$sort" => { user_id: 1 }
        }
      }
    )

    if self.user_states.blank?
      self.user_states = [{ "user_id" => user_id, state => value }]
    else
      self.user_states << { "user_id" => user_id, state => value }
      self.user_states.sort_by! { |user_state| user_state["user_id"] }
    end
  end

  def update_user_state(user_id, state, value)
    filter_spec = { _id: self.id, user_states: { "$elemMatch" => { "user_id" => user_id } } }
    update_spec = { "$set" => { "user_states.$.#{state}" => value } }
    self.collection.update_one(filter_spec, update_spec)

    user_state = user_states.bsearch { |user_state| user_state["user_id"] <=> user_id }
    user_state[state] = value
  end

  def upsert_user_state(user_id, state, value)
    if user_states.blank?
      insert_user_state(user_id, state, value)
      return
    end

    user_state = user_states.bsearch { |user_state| user_state["user_id"] <=> user_id }
    if user_state.blank?
      insert_user_state(user_id, state, value)
      return
    end

    update_user_state(user_id, state, value)
  end

  def find_user_state(user_id, state)
    return if user_states.blank?

    user_state = user_states.bsearch { |user_state| user_id <=> user_state["user_id"] }
    return if user_state.blank?

    user_state[state]
  end
end
