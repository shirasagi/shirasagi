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

  module Site
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_site

    included do
      belongs_to :site, class_name: "SS::Site"

      validates :site_id, presence: true
      before_validation :set_site_id, if: ->{ @cur_site }

      scope :site, ->(site) { where(site_id: site.id) }
    end

    private
      def set_site_id
        self.site_id ||= @cur_site.id
      end
  end
end
