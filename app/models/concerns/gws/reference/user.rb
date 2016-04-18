module Gws::Reference
  module User
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_user

    included do
      field :user_uid, type: String
      field :user_name, type: String
      field :user_tel, type: String
      belongs_to :user, class_name: "Gws::User"

      before_validation :set_user_id, if: ->{ @cur_user }

      scope :user, ->(user) { where(user_id: user.id) }
    end

    def user_uid
      self[:user_uid] || user.try(:uid)
    end

    def user_name
      self[:user_name] || user.try(:name)
    end

    def user_tel
      self[:user_tel] || user.try(:tel)
    end

    def user_long_name
      user_uid.present? ? "#{user_name} (#{user_uid})" : user_name
    end

    private
      def set_user_id
        self.user_id   ||= @cur_user.id
        self.user_uid  = @cur_user.uid unless self[:user_uid]
        self.user_name = @cur_user.name unless self[:user_name]
        self.user_tel  = @cur_user.tel unless self[:user_tel]
      end
  end
end
