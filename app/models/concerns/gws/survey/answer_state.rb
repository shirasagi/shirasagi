module Gws::Survey::AnswerState
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :answered_users_hash, type: Hash

    scope :and_answered, ->(user) { exists("answered_users_hash.#{user.id}" => true) }
    scope :and_unanswered, ->(user) { exists("answered_users_hash.#{user.id}" => false) }
  end

  module ClassMethods
    def answered_state_options
      %w(both unanswered answered).map { |m| [I18n.t("gws/survey.options.answered_state.#{m}"), m] }
    end

    def sort_options
      %w(due_date_desc due_date_asc updated_desc updated_asc created_desc created_asc).map do |k|
        [I18n.t("gws/survey.options.sort.#{k}"), k]
      end
    end
  end

  def answered_at(user)
    return if answered_users_hash.blank?
    answered_users_hash[user.id.to_s].try(:in_time_zone)
  end

  alias answered? answered_at

  def set_answered!(user)
    # to update hash partially, use `#persist_atomic_operations` method.
    # be careful, you must not use `#set` method. this method update hash totally.
    persist_atomic_operations('$set' => { "answered_users_hash.#{user.id}" => Time.zone.now.utc })
  end

  def unset_answered!(user)
    # to update hash partially, use `#persist_atomic_operations` method.
    # be careful, you must not use `#set` method. this method update hash totally.
    persist_atomic_operations('$unset' => { "answered_users_hash.#{user.id}" => '' })
  end

  def answered_state_options
    self.class.answered_state_options
  end

  def sort_options
    self.class.sort_options
  end

  def answered_users
    answered = self.answered_users_hash.to_a.select { |user_id, browsed_at| browsed_at.present? }
    answered_user_ids = answered.map { |user_id, browsed_at| user_id }
    Gws::User.in(id: answered_user_ids)
  end
end
