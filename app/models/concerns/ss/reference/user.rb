module SS::Reference
  module User
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_user

    included do
      belongs_to :user, class_name: "SS::User"
      before_validation :set_user_id, if: ->{ @cur_user }

      scope :user, ->(user) { where(user_id: user.id) }
    end

    private
      def set_user_id
        self.user_id ||= @cur_user.id
      end
  end
end
