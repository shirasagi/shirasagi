module SS::Addon
  module UserGroupHistory
    extend ActiveSupport::Concern
    extend SS::Addon

    def group_histories
      SS::UserGroupHistory.where(user_id: id)
    end
  end
end
